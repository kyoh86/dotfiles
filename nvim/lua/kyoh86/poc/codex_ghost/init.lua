local M = {}

--- Load annotation library: vim.uv
_ = vim.uv

local config = require("kyoh86.poc.codex_ghost.config")

--- @class codex_ghost.RequestToken

--- Create new RequestToken
--- @return codex_ghost.RequestToken
local function new_token()
  return {}
end

--- @class codex_ghost.Position
--- @field buf integer
--- @field row integer
--- @field col integer

--- @class codex_ghost.LastPrompting
--- @field prompt string
--- @field suggestion string[]

--- @class codex_ghost.State
--- @field request_token codex_ghost.RequestToken
--- @field pos codex_ghost.Position|nil
--- @field suggestion string[]|nil
--- @field job vim.SystemObj|nil
--- @field job_timer uv_timer_t|nil
--- @field last codex_ghost.LastPrompting|nil
--- @field config codex_ghost.Config|nil
--- @field base_tick integer|nil
--- @field preview {buf: integer, win: integer}|nil

--- @type codex_ghost.State
local state = {
  request_token = new_token(),
}

local function close_preview()
  if state.preview and vim.api.nvim_win_is_valid(state.preview.win) then
    pcall(vim.api.nvim_win_close, state.preview.win, true)
  end
  if state.preview and vim.api.nvim_buf_is_valid(state.preview.buf) then
    pcall(vim.api.nvim_buf_delete, state.preview.buf, { force = true })
  end
  state.preview = nil
end

local function clear_job()
  if state.job then
    pcall(function()
      state.job:kill("term")
    end)
  end
  if state.job_timer and not state.job_timer:is_closing() then
    state.job_timer:stop()
    state.job_timer:close()
  end
  state.job_timer = nil
  state.job = nil
end

local function clear_mark()
  state.suggestion = nil
  state.base_tick = nil
  close_preview()
end

local function clear_pos()
  state.pos = nil
end

local function reset()
  clear_job()
  clear_mark()
  clear_pos()
  close_preview()
end

local function apply_current()
  if not state.pos or not state.suggestion then
    return false, "no suggestion"
  end
  if not vim.api.nvim_buf_is_valid(state.pos.buf) then
    return false, "invalid buffer"
  end
  local buf = state.pos.buf
  if vim.api.nvim_buf_get_changedtick(buf) ~= state.base_tick then
    local yesno = vim.fn.confirm("There're lines which changed while I think. Sure you want to apply the suggestion?: ", "&Yes\n&No")
    if yesno == 1 then --yes
    elseif yesno == 2 then -- no
      return true, "conflict"
    else -- cancel
      return true, "conflict"
    end
  end
  local curr_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local insert_at = math.min(state.pos.row + 1, #curr_lines)
  local ok, err = pcall(vim.api.nvim_buf_set_lines, buf, insert_at, insert_at, false, state.suggestion)
  if not ok then
    return false, err
  end
  return true, "applied"
end

local function apply()
  local ok, msg = apply_current()
  if not ok then
    vim.notify("Codex apply failed: " .. msg, vim.log.levels.ERROR)
  elseif msg == "conflict" then
    vim.notify("Codex apply: conflicted suggestions are cancelled", vim.log.levels.WARN)
  else
    vim.notify("Codex applied", vim.log.levels.INFO)
  end
  reset()
end

local function build_preview_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "Codex suggestion",
    string.format("File: %s", vim.fn.fnamemodify(vim.api.nvim_buf_get_name(state.pos.buf), ":~:.")),
    "Apply: <CR>/a | Close: q",
    "",
    string.format("``````%s", vim.bo[state.pos.buf].filetype),
  })
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, state.suggestion)
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "``````" })

  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  vim.keymap.set("n", "<CR>", apply, { buffer = buf, silent = true })
  vim.keymap.set("n", "a", apply, { buffer = buf, silent = true })
  vim.keymap.set("n", "q", reset, { buffer = buf, silent = true })

  return buf, #state.suggestion + 6
end

local function open_preview()
  if not state.pos or not state.suggestion then
    return
  end
  close_preview()

  local buf, lines = build_preview_buffer()

  local width = math.min(math.max(40, math.floor(vim.o.columns * 0.6)), vim.o.columns)
  local height = math.min(lines, math.max(6, math.floor(vim.o.lines * 0.6)))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = "single",
  })
  state.preview = { buf = buf, win = win }
end

local function cancel_pending(reason)
  state.request_token = new_token()
  if state.job ~= nil and state.config.notify_on_cancel then
    vim.notify(reason or "Codex ghost cancelled", vim.log.levels.INFO)
  end
  reset()
end

local function should_skip(buf, cfg)
  local ft = vim.bo[buf].filetype
  local bt = vim.bo[buf].buftype
  if vim.list_contains(cfg.disable_buftypes, bt) then
    return true
  end
  if vim.list_contains(cfg.disable_filetypes, ft) then
    return true
  end
  if vim.bo[buf].readonly then
    return true
  end
  if vim.api.nvim_buf_line_count(buf) > cfg.max_lines then
    return true
  end
  return false
end

local function log_event(opts, msg)
  if not opts.log_file or opts.log_file == "" then
    return
  end
  local ok, fh = pcall(io.open, opts.log_file, "a")
  if not ok or not fh then
    return
  end
  local time = os.date("%Y-%m-%d %H:%M:%S")
  fh:write(string.format("[%s] %s\n", time, msg))
  fh:close()
end

local function relpath(path)
  if path == "" then
    return "[No Name]"
  end
  return vim.fn.fnamemodify(path, ":~:.")
end

--- Collect context to pass to the Codex
--- @param pos codex_ghost.Position
--- @param opts codex_ghost.Config
local function collect_context(pos, opts)
  local lines = vim.api.nvim_buf_get_lines(pos.buf, 0, -1, true)
  local cur_line = lines[pos.row + 1] or ""
  if cur_line == "" and pos.row >= #lines then
    return nil, nil
  end
  local before_cursor = cur_line:sub(1, pos.col)
  local after_cursor = cur_line:sub(pos.col + 1)

  local before = {}
  local before_start = math.max(0, pos.row - opts.context_before)
  for i = before_start + 1, pos.row do
    before[#before + 1] = lines[i]
  end
  before[#before + 1] = before_cursor

  local after = { after_cursor }
  local after_end = math.min(#lines, pos.row + opts.context_after + 1)
  for i = pos.row + 2, after_end do
    after[#after + 1] = lines[i]
  end

  return table.concat(before, "\n"), table.concat(after, "\n")
end

--- Build prompt message to pass to the Codex
--- @param pos codex_ghost.Position
--- @param opts codex_ghost.Config
local function build_prompt(pos, opts)
  local before, after = collect_context(pos, opts)
  if not before then
    return nil
  end
  local ft = vim.bo[pos.buf].filetype or "plain"
  return table.concat({
    "You are a code completion engine.",
    "Continue the code at the cursor position.",
    "Return only the continuation to insert (no markdown, no fences, no explanations).",
    "Keep indentation consistent and avoid repeating the existing suffix.",
    string.format("Filetype: %s", ft),
    string.format("Filename: %s", relpath(vim.api.nvim_buf_get_name(pos.buf))),
    string.format("Cursor: line %d, column %d", pos.row + 1, pos.col + 1),
    "--- BEFORE ---",
    before,
    "--- AFTER ---",
    after,
  }, "\n")
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

local function run_request(buf, row, col, opts)
  if vim.fn.executable("codex") == 0 then
    vim.notify("codex CLI not found in PATH", vim.log.levels.ERROR)
    return
  end
  if should_skip(buf, opts) then
    return
  end
  log_event(opts, string.format("request row=%d col=%d file=%s", row + 1, col + 1, relpath(vim.api.nvim_buf_get_name(buf))))

  clear_mark()

  local token = new_token()
  state.request_token = token
  local pos = { buf = buf, row = row, col = col }
  state.pos = pos
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local prompt = build_prompt(pos, opts)
  if not prompt then
    return
  end
  close_preview()
  state.pos = nil
  state.suggestion = nil
  state.base_tick = nil
  local tmpfile = vim.fn.tempname()

  local args = { "codex", "exec" }
  if opts.model then
    args[#args + 1] = "-m"
    args[#args + 1] = opts.model
  end
  vim.list_extend(args, { "--color=never", "--skip-git-repo-check", "--output-last-message", tmpfile, "-" })

  clear_job()
  state.job = vim.system(args, { stdin = prompt, text = true }, function(obj)
    vim.schedule(function()
      if state.job_timer and not state.job_timer:is_closing() then
        state.job_timer:stop()
        state.job_timer:close()
      end
      state.job_timer = nil

      local suggestion = read_file(tmpfile):gsub("\r", "")
      os.remove(tmpfile)
      clear_mark()

      if token ~= state.request_token then
        return
      end
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      if vim.api.nvim_buf_get_changedtick(buf) ~= tick then
        return
      end
      if obj.code ~= 0 then
        vim.notify("Codex ghost failed: " .. (obj.stderr or obj.stdout or "unknown error"), vim.log.levels.ERROR)
        log_event(opts, string.format("fail code=%s msg=%s", tostring(obj.code), obj.stderr or obj.stdout or "unknown"))
        return
      end
      if not suggestion or suggestion == "" then
        vim.notify("Codex suggested empty")
        log_event(opts, "empty suggestion")
        return
      end
      local lines = vim.split(suggestion, "\n", { plain = true })
      state.suggestion = lines
      state.last = { prompt = prompt, suggestion = lines }
      state.pos = pos
      state.base_tick = tick
      open_preview()
      log_event(opts, string.format("ok lines=%d file=%s", #lines, relpath(vim.api.nvim_buf_get_name(buf))))
    end)
  end)
  if opts.timeout_ms and opts.timeout_ms > 0 then
    state.job_timer = vim.defer_fn(function()
      if state.job then
        log_event(opts, "timeout; killing job")
        cancel_pending("Codex ghost timed out")
      end
    end, opts.timeout_ms)
  end
end

function M.dismiss()
  reset()
end

function M.accept()
  apply()
end

function M.request()
  run_request(vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1] - 1, vim.api.nvim_win_get_cursor(0)[2], vim.tbl_extend("force", state.config, {}))
end

function M.show_last()
  if not state.last then
    vim.notify("Codex ghost: no history", vim.log.levels.INFO)
    return
  end
  vim.notify(table.concat(state.last.suggestion, "\\n"), vim.log.levels.INFO)
end

function M.setup(opts)
  state.config = config.setup(opts)

  vim.api.nvim_create_user_command("CodexGhost", M.request, {})
  vim.api.nvim_create_user_command("CodexGhostAccept", M.accept, {})
  vim.api.nvim_create_user_command("CodexGhostDismiss", M.dismiss, {})
  vim.api.nvim_create_user_command("CodexGhostShowLast", M.show_last, {})
end

-- testing helper
function M._stage_for_test(pos, suggestion, opts)
  local target = vim.api.nvim_get_current_buf()
  pos.buf = target
  state.pos = pos
  state.suggestion = suggestion
  state.base_tick = (opts and opts.base_tick) or vim.api.nvim_buf_get_changedtick(target)
  if not (opts and opts.no_preview) then
    open_preview()
  end
end

return M
