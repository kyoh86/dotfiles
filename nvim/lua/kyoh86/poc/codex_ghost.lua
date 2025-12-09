local M = {}

local ns = vim.api.nvim_create_namespace("kyoh86-codex-ghost")
local ghost_hl = "CodexGhost"
local defaults = {
  context_before = 120,
  context_after = 60,
  highlight = ghost_hl, -- extmark highlight group
  base_highlight = "Comment", -- link target if ghost group is missing
  model = nil,
}

local state = {
  request_id = 0,
  mark = nil,
  buf = nil,
  text = nil,
  insert = nil,
}

local function clear_mark()
  if state.mark and state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    pcall(vim.api.nvim_buf_del_extmark, state.buf, ns, state.mark)
  end
  state.mark = nil
  state.buf = nil
  state.text = nil
  state.insert = nil
end

local function show_ghost(buf, row, col, text, hl)
  clear_mark()
  local lines = vim.split(text, "\n", { plain = true })
  if #lines == 0 then
    return
  end

  local virt_text = nil
  local virt_lines = nil
  local virt_text_pos = nil
  local insert = nil

  if #lines == 1 then
    virt_text = { { lines[1], hl or ghost_hl } }
    virt_text_pos = "inline" -- show after the cursor column without covering buffer text
    insert = { row = row, col = col, lines = { lines[1] } }
  else
    local prefix = (vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1] or ""):sub(1, col)
    local pad = string.rep(" ", vim.fn.strdisplaywidth(prefix))
    virt_lines = {}
    local padded = {}
    for i, line in ipairs(lines) do
      local padded_line = pad .. line
      virt_lines[#virt_lines + 1] = { { padded_line, hl or ghost_hl } }
      padded[#padded + 1] = padded_line
    end
    insert = { row = row + 1, col = 0, lines = padded }
  end

  state.buf = buf
  state.text = text
  state.insert = insert
  state.mark = vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
    virt_text = virt_text,
    virt_text_pos = virt_text_pos,
    virt_lines = virt_lines,
    virt_lines_above = false,
    hl_mode = "combine",
    priority = 200,
  })
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

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local content = fd:read("*a")
  fd:close()
  return content
end

function M.dismiss()
  clear_mark()
end

function M.accept()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) or not state.insert then
    return
  end
  local row, col = state.insert.row, state.insert.col
  local lines = state.insert.lines
  if not lines or #lines == 0 then
    clear_mark()
    return
  end
  vim.api.nvim_buf_set_text(state.buf, row, col, row, col, lines)
  clear_mark()
end

function M.request(opts)
  local config = vim.tbl_extend("force", defaults, opts or {})
  if vim.fn.executable("codex") == 0 then
    vim.notify("codex CLI not found in PATH", vim.log.levels.ERROR)
    return
  end

  clear_mark()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then
    vim.notify("Codex ghost: buffer type is not supported", vim.log.levels.WARN)
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local prompt = build_prompt(buf, row, col, config)
  local tmpfile = vim.fn.tempname()

  local args = { "codex", "exec" }
  if config.model then
    args[#args + 1] = "-m"
    args[#args + 1] = config.model
  end
  vim.list_extend(args, { "--color=never", "--skip-git-repo-check", "--output-last-message", tmpfile, "-" })

  state.request_id = state.request_id + 1
  local request_id = state.request_id
  local tick = vim.api.nvim_buf_get_changedtick(buf)

  vim.system(args, { stdin = prompt, text = true }, function(obj)
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
      -- normalize newlines; keep trailing empty line if present
      suggestion = suggestion:gsub("\r", "")
      show_ghost(buf, row, col, suggestion, config.highlight)
    end)
  end)
end

function M.setup(opts)
  defaults = vim.tbl_extend("force", defaults, opts or {})
  -- lightweight ghost look; users can override CodexGhost or pass a custom highlight name
  vim.api.nvim_set_hl(0, ghost_hl, { link = defaults.base_highlight, default = true })

  vim.api.nvim_create_user_command("CodexGhost", function()
    M.request()
  end, {})
  vim.api.nvim_create_user_command("CodexGhostAccept", function()
    M.accept()
  end, {})
  vim.api.nvim_create_user_command("CodexGhostDismiss", function()
    M.dismiss()
  end, {})
end

return M
