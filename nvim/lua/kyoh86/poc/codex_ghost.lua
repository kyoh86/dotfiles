local M = {}

local ghost_ns = vim.api.nvim_create_namespace("kyoh86-codex-ghost")
local ghost_hl = "CodexGhost"

--- @class codex_ghost.Config
--- @field context_before integer
--- @field context_after integer
--- @field model string|nil
--- @field max_lines integer
--- @field disable_filetypes string[]
--- @field disable_buftypes string[]
--- @field timeout_ms integer
--- @field log_file string|nil
--- @field pending_text string
--- @field notify_on_cancel boolean

--- @type codex_ghost.Config
local defaults = {
  context_before = 120,
  context_after = 60,
  model = nil,
  max_lines = 4000,
  disable_filetypes = {},
  disable_buftypes = { "help", "prompt", "quickfix", "terminal" },
  timeout_ms = 20000,
  log_file = nil, -- e.g. "/tmp/codex_ghost.log"
  pending_text = "⏳ Codex",
  notify_on_cancel = true,
}

--- @class codex_ghost.RequestToken

--- Create new RequestToken
--- @return codex_ghost.RequestToken
local function new_token()
  return {}
end

--- @class codex_ghost.InsertTargetText
--- @field mode "text"
--- @field row integer
--- @field col integer
--- @field lines string[]

--- @class codex_ghost.InsertTargetLines
--- @field mode "lines"
--- @field row integer
--- @field lines string[]

--- @class codex_ghost.LastPrompting
--- @field prompt string
--- @field lines string[]

--- @class State
--- @field request_token codex_ghost.RequestToken
--- @field pending_buf integer|nil
--- @field buf integer|nil
--- @field insert  codex_ghost.InsertTargetText|codex_ghost.InsertTargetLines|nil
--- @field job vim.SystemObj|nil
--- @field job_timer uv_timer_t|nil
--- @field last codex_ghost.LastPrompting|nil
--- @field config codex_ghost.Config

--- @type State
local state = {
  request_token = new_token(),
  pending_buf = nil,
  buf = nil,
  insert = nil,
  job = nil,
  job_timer = nil,
  last = nil,
  config = defaults,
}

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
  if state.pending_buf and vim.api.nvim_buf_is_valid(state.pending_buf) then
    pcall(vim.api.nvim_buf_clear_namespace, state.pending_buf, ghost_ns, 0, -1)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    pcall(vim.api.nvim_buf_clear_namespace, state.buf, ghost_ns, 0, -1)
  end
  state.pending_buf = nil
  state.buf = nil
  state.insert = nil
end

local function reset()
  clear_job()
  clear_mark()
end

local function cancel_pending(reason)
  state.request_token = new_token()
  reset()
  if state.job ~= nil and state.config.notify_on_cancel then
    vim.notify(reason or "Codex ghost cancelled", vim.log.levels.INFO)
  end
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
  if vim.bo[buf].readonly then
    return true
  end
  if vim.api.nvim_buf_line_count(buf) > cfg.max_lines then
    return true
  end
  return false
end

local function log_event(cfg, msg)
  if not cfg.log_file or cfg.log_file == "" then
    return
  end
  local ok, fh = pcall(io.open, cfg.log_file, "a")
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

local function collect_context(buf, row, col, opts)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local cur_line = lines[row + 1] or ""
  if cur_line == "" and row >= #lines then
    return nil, nil
  end
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
  if not before then
    return nil
  end
  local ft = vim.bo[buf].filetype or "plain"
  return table.concat({
    "You are a code completion engine.",
    "Continue the code at the cursor position.",
    "Return only the continuation to insert (no markdown, no fences, no explanations).",
    "Keep indentation consistent and avoid repeating the existing suffix.",
    string.format("Filetype: %s", ft),
    string.format("Filename: %s", relpath(vim.api.nvim_buf_get_name(buf))),
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
  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count == 0 then
    return
  end
  row = math.min(row, line_count - 1)

  local hlname = hl or ghost_hl
  local cur = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1] or ""
  col = math.min(col, #cur)
  local prefix = cur:sub(1, col)
  local pad = string.rep(" ", vim.fn.strdisplaywidth(prefix))

  if #lines == 1 then
    state.buf = buf
    state.insert = { mode = "text", row = row, col = col, lines = lines }
    vim.api.nvim_buf_set_extmark(buf, ghost_ns, row, col, {
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
  vim.api.nvim_buf_set_extmark(buf, ghost_ns, row, col, {
    virt_lines = virt_lines,
    virt_lines_above = false,
    hl_mode = "combine",
    priority = 200,
  })
end

local function show_pending(buf, row, text)
  if not text or text == "" then
    return
  end
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count == 0 then
    return
  end
  row = math.min(row, line_count - 1)
  state.pending_buf = buf
  pcall(vim.api.nvim_buf_set_extmark, buf, ghost_ns, row, 0, {
    virt_text = { { text, ghost_hl } },
    virt_text_pos = "eol",
    hl_mode = "combine",
    priority = 50,
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
  log_event(config, string.format("request row=%d col=%d file=%s", row + 1, col + 1, relpath(vim.api.nvim_buf_get_name(buf))))

  clear_mark()
  show_pending(buf, row, config.pending_text)
  state.request_token = new_token()
  local token = state.request_token
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local prompt = build_prompt(buf, row, col, config)
  if not prompt then
    clear_mark()
    return
  end
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
      if state.job_timer and not state.job_timer:is_closing() then
        state.job_timer:stop()
        state.job_timer:close()
      end
      state.job_timer = nil

      if token ~= state.request_token then
        os.remove(tmpfile)
        clear_mark()
        return
      end
      if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_changedtick(buf) ~= tick then
        os.remove(tmpfile)
        clear_mark()
        return
      end
      if obj.code ~= 0 then
        os.remove(tmpfile)
        vim.notify("Codex ghost failed: " .. (obj.stderr or obj.stdout or "unknown error"), vim.log.levels.ERROR)
        log_event(config, string.format("fail code=%s msg=%s", tostring(obj.code), obj.stderr or obj.stdout or "unknown"))
        clear_mark()
        return
      end
      local suggestion = read_file(tmpfile)
      os.remove(tmpfile)
      if not suggestion or suggestion == "" then
        clear_mark()
        log_event(config, "empty suggestion")
        return
      end
      suggestion = suggestion:gsub("\r", "")
      local has_trailing_newline = suggestion:sub(-1) == "\n"
      local lines = vim.split(suggestion, "\n", { plain = true })
      if has_trailing_newline then
        table.insert(lines, "")
      end

      state.last = { prompt = prompt, lines = lines }
      show_ghost(buf, row, col, lines, ghost_hl)
      log_event(config, string.format("ok lines=%d file=%s", #lines, relpath(vim.api.nvim_buf_get_name(buf))))
    end)
  end)
  if config.timeout_ms and config.timeout_ms > 0 then
    state.job_timer = vim.defer_fn(function()
      if state.job then
        log_event(config, "timeout; killing job")
        cancel_pending("Codex ghost timed out")
      end
    end, config.timeout_ms)
  end
end

function M.dismiss()
  reset()
end

function M.accept()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  local insert = state.insert
  if not insert then
    return
  end
  local lines = insert.lines
  if not lines or #lines == 0 then
    reset()
    return
  end

  if insert.mode == "lines" then
    local lc = vim.api.nvim_buf_line_count(state.buf)
    local target = math.min(insert.row, lc)
    vim.api.nvim_buf_set_lines(state.buf, target, target, false, lines)
  else
    local lc = vim.api.nvim_buf_line_count(state.buf)
    local row = math.min(insert.row, math.max(lc - 1, 0))
    local cur = vim.api.nvim_buf_get_lines(state.buf, row, row + 1, true)[1] or ""
    local col = math.min(insert.col, #cur)
    vim.api.nvim_buf_set_text(state.buf, row, col, row, col, lines)
  end
  reset()
end

function M.request(opts)
  local config = vim.tbl_extend("force", state.config, opts or {})
  run_request(vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1] - 1, vim.api.nvim_win_get_cursor(0)[2], config)
end

function M.show_last()
  if not state.last then
    vim.notify("Codex ghost: no history", vim.log.levels.INFO)
    return
  end
  vim.notify(table.concat(state.last.lines, "\\n"), vim.log.levels.INFO)
end

local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("kyoh86-codex-ghost", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMovedI", "InsertLeave", "BufLeave" }, {
    group = group,
    callback = function()
      cancel_pending("Codex ghost cancelled (moved or left insert)")
    end,
  })
end

function M.setup(opts)
  state.config = vim.tbl_extend("force", defaults, opts or {})
  vim.api.nvim_set_hl(0, ghost_hl, { link = "Comment", default = true })

  vim.api.nvim_create_user_command("CodexGhost", function()
    M.request()
  end, {})
  vim.api.nvim_create_user_command("CodexGhostAccept", function()
    M.accept()
  end, {})
  vim.api.nvim_create_user_command("CodexGhostDismiss", function()
    M.dismiss()
  end, {})
  vim.api.nvim_create_user_command("CodexGhostShowLast", function()
    M.show_last()
  end, {})

  setup_autocmds()
end

return M
