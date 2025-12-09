local M = {}

local ns = vim.api.nvim_create_namespace("kyoh86-codex-ghost")
local ghost_hl = "CodexGhost"

local defaults = {
	context_before = 120,
	context_after = 60,
	highlight = ghost_hl, -- extmark highlight group
	base_highlight = "Comment", -- link target if ghost group is missing
	model = nil,
	auto_trigger = true,
	debounce_ms = 200,
	max_lines = 4000,
	disable_filetypes = {},
	disable_buftypes = { "help", "prompt", "quickfix", "terminal" },
	skip_readonly = true,
}

local state = {
	request_id = 0,
	mark = nil,
	buf = nil,
	insert = nil,
	timer = nil,
	job = nil,
	last = nil, -- { prompt, lines }
	enabled = true,
	config = defaults,
}

local function clear_timer()
	if state.timer and not state.timer:is_closing() then
		state.timer:stop()
		state.timer:close()
	end
	state.timer = nil
end

local function clear_job()
	if state.job then
		pcall(function()
			state.job:kill("term")
		end)
	end
	state.job = nil
end

local function clear_mark()
	if state.mark and state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		pcall(vim.api.nvim_buf_del_extmark, state.buf, ns, state.mark)
	end
	state.mark = nil
	state.buf = nil
	state.insert = nil
end

local function reset()
	clear_timer()
	clear_job()
	clear_mark()
end

local function in_list(value, list)
	for _, v in ipairs(list or {}) do
		if v == value then
			return true
		end
	end
	return false
end

local function should_skip(buf, cfg)
	local ft = vim.bo[buf].filetype
	local bt = vim.bo[buf].buftype
	if in_list(bt, cfg.disable_buftypes) then
		return true
	end
	if in_list(ft, cfg.disable_filetypes) then
		return true
	end
	if cfg.skip_readonly and vim.bo[buf].readonly then
		return true
	end
	if vim.api.nvim_buf_line_count(buf) > cfg.max_lines then
		return true
	end
	return false
end

local function relpath(path)
	if path == "" then
		return "[No Name]"
	end
	return vim.fn.fnamemodify(path, ":~:.")
end

local function collect_context(buf, row, col, opts)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
	local cur_line = lines[row + 1] or ""
	local before_cursor = cur_line:sub(1, col)
	local after_cursor = cur_line:sub(col + 1)

	local before = {}
	local before_start = math.max(0, row - opts.context_before)
	for i = before_start + 1, row do
		before[#before + 1] = lines[i]
	end
	before[#before + 1] = before_cursor

	local after = { after_cursor }
	local after_end = math.min(#lines, row + opts.context_after + 1)
	for i = row + 2, after_end do
		after[#after + 1] = lines[i]
	end

	return table.concat(before, "\n"), table.concat(after, "\n")
end

local function build_prompt(buf, row, col, opts)
	local before, after = collect_context(buf, row, col, opts)
	return table.concat({
		"You are a code completion engine.",
		"Continue the code at the cursor position.",
		"Return only the continuation to insert (no markdown, no fences, no explanations).",
		"Keep indentation consistent and avoid repeating the existing suffix.",
		string.format("File: %s", relpath(vim.api.nvim_buf_get_name(buf))),
		string.format("Cursor: line %d, column %d", row + 1, col + 1),
		"--- BEFORE ---",
		before,
		"--- AFTER ---",
		after,
	}, "\n")
end

local function show_ghost(buf, row, col, lines, hl)
	clear_mark()
	if #lines == 0 then
		return
	end

	local hlname = hl or ghost_hl
	local prefix = (vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1] or ""):sub(1, col)
	local pad = string.rep(" ", vim.fn.strdisplaywidth(prefix))

	if #lines == 1 then
		state.buf = buf
		state.insert = { mode = "text", row = row, col = col, lines = lines }
		state.mark = vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
			virt_text = { { lines[1], hlname } },
			virt_text_pos = "inline",
			hl_mode = "combine",
			priority = 200,
		})
		return
	end

	local virt_lines = {}
	local insert_lines = {}
	for _, line in ipairs(lines) do
		local padded_line = pad .. line
		virt_lines[#virt_lines + 1] = { { padded_line, hlname } }
		insert_lines[#insert_lines + 1] = padded_line
	end

	state.buf = buf
	state.insert = { mode = "lines", row = row + 1, lines = insert_lines }
	state.mark = vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
		virt_lines = virt_lines,
		virt_lines_above = false,
		hl_mode = "combine",
		priority = 200,
	})
end

local function read_file(path)
	local fd = io.open(path, "r")
	if not fd then
		return nil
	end
	local content = fd:read("*a")
	fd:close()
	return content
end

local function run_request(buf, row, col, config)
	if vim.fn.executable("codex") == 0 then
		vim.notify("codex CLI not found in PATH", vim.log.levels.ERROR)
		return
	end
	if should_skip(buf, config) then
		return
	end

	clear_mark()
	state.request_id = state.request_id + 1
	local request_id = state.request_id
	local tick = vim.api.nvim_buf_get_changedtick(buf)
	local prompt = build_prompt(buf, row, col, config)
	local tmpfile = vim.fn.tempname()

	local args = { "codex", "exec" }
	if config.model then
		args[#args + 1] = "-m"
		args[#args + 1] = config.model
	end
	vim.list_extend(args, { "--color=never", "--skip-git-repo-check", "--output-last-message", tmpfile, "-" })

	clear_job()
	state.job = vim.system(args, { stdin = prompt, text = true }, function(obj)
		vim.schedule(function()
			if request_id ~= state.request_id then
				os.remove(tmpfile)
				return
			end
			if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_changedtick(buf) ~= tick then
				os.remove(tmpfile)
				return
			end
			if obj.code ~= 0 then
				os.remove(tmpfile)
				vim.notify(
					"Codex ghost failed: " .. (obj.stderr or obj.stdout or "unknown error"),
					vim.log.levels.ERROR
				)
				return
			end
			local suggestion = read_file(tmpfile)
			os.remove(tmpfile)
			if not suggestion or suggestion == "" then
				clear_mark()
				return
			end
			suggestion = suggestion:gsub("\r", "")
			local has_trailing_newline = suggestion:sub(-1) == "\n"
			local lines = vim.split(suggestion, "\n", { plain = true })
			if has_trailing_newline then
				table.insert(lines, "")
			end

			state.last = { prompt = prompt, lines = lines }
			show_ghost(buf, row, col, lines, config.highlight)
		end)
	end)
end

function M.dismiss()
	reset()
end

function M.accept()
	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) or not state.insert then
		return
	end
	local insert = state.insert
	local lines = insert.lines
	if not lines or #lines == 0 then
		reset()
		return
	end

	if insert.mode == "lines" then
		vim.api.nvim_buf_set_lines(state.buf, insert.row, insert.row, false, lines)
	else
		vim.api.nvim_buf_set_text(state.buf, insert.row, insert.col, insert.row, insert.col, lines)
	end
	reset()
end

local function schedule_request(config)
	if not state.enabled then
		return
	end
	local buf = vim.api.nvim_get_current_buf()
	if should_skip(buf, config) then
		return
	end
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	clear_timer()
	state.timer = vim.defer_fn(function()
		run_request(buf, row, col, config)
	end, config.debounce_ms)
end

function M.request(opts)
	local config = vim.tbl_extend("force", state.config, opts or {})
	state.enabled = true
	clear_timer()
	run_request(
		vim.api.nvim_get_current_buf(),
		vim.api.nvim_win_get_cursor(0)[1] - 1,
		vim.api.nvim_win_get_cursor(0)[2],
		config
	)
end

function M.toggle(enable)
	if enable ~= nil then
		state.enabled = enable
	else
		state.enabled = not state.enabled
	end
	if not state.enabled then
		reset()
	end
	return state.enabled
end

function M.show_last()
	if not state.last then
		vim.notify("Codex ghost: no history", vim.log.levels.INFO)
		return
	end
	vim.notify(table.concat(state.last.lines, "\\n"), vim.log.levels.INFO)
end

local function setup_autocmds(config)
	local group = vim.api.nvim_create_augroup("kyoh86-codex-ghost", { clear = true })
	if not config.auto_trigger then
		vim.api.nvim_clear_autocmds({ group = group })
		return
	end
	vim.api.nvim_create_autocmd({ "TextChangedI", "InsertCharPre" }, {
		group = group,
		callback = function()
			schedule_request(config)
		end,
	})
	vim.api.nvim_create_autocmd({ "CursorMovedI", "InsertLeave", "BufLeave" }, {
		group = group,
		callback = function()
			clear_timer()
			clear_job()
			clear_mark()
		end,
	})
end

function M.setup(opts)
	state.config = vim.tbl_extend("force", defaults, opts or {})
	state.enabled = true
	vim.api.nvim_set_hl(0, ghost_hl, { link = state.config.base_highlight, default = true })

	vim.api.nvim_create_user_command("CodexGhost", function()
		M.request()
	end, {})
	vim.api.nvim_create_user_command("CodexGhostAccept", function()
		M.accept()
	end, {})
	vim.api.nvim_create_user_command("CodexGhostDismiss", function()
		M.dismiss()
	end, {})
	vim.api.nvim_create_user_command("CodexGhostToggle", function()
		local enabled = M.toggle()
		vim.notify(string.format("Codex ghost %s", enabled and "enabled" or "disabled"))
	end, {})
	vim.api.nvim_create_user_command("CodexGhostShowLast", function()
		M.show_last()
	end, {})

	setup_autocmds(state.config)
end

return M
