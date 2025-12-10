local M = {}

local screen = require("kyoh86.poc.codex_ghost.screen")
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

--- @type codex_ghost.State
local state = {
  request_token = new_token(),
  pos = nil,
  suggestion = nil,
  job = nil,
  job_timer = nil,
  last = nil,
  config = nil,
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
  if state.pos then
    screen.clear(state.pos.buf)
  end
  state.suggestion = nil
end

local function clear_pos()
  state.pos = nil
end

local function reset()
  clear_job()
  clear_mark()
  clear_pos()
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

local function run_request(buf, row, col, conf)
  if vim.fn.executable("codex") == 0 then
    vim.notify("codex CLI not found in PATH", vim.log.levels.ERROR)
    return
  end
  if should_skip(buf, conf) then
    return
  end
  log_event(conf, string.format("request row=%d col=%d file=%s", row + 1, col + 1, relpath(vim.api.nvim_buf_get_name(buf))))

  clear_mark()

  local token = new_token()
  state.request_token = token
  local pos = { buf = buf, row = row, col = col }
  state.pos = pos
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local prompt = build_prompt(pos, conf)
  if not prompt then
    return
  end
  screen.show_pending(pos, conf.pending_text)

  local tmpfile = vim.fn.tempname()

  local args = { "codex", "exec" }
  if conf.model then
    args[#args + 1] = "-m"
    args[#args + 1] = conf.model
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
        log_event(conf, string.format("fail code=%s msg=%s", tostring(obj.code), obj.stderr or obj.stdout or "unknown"))
        return
      end
      if not suggestion or suggestion == "" then
        vim.notify("Codex suggested empty")
        log_event(conf, "empty suggestion")
        return
      end
      local lines = vim.split(suggestion, "\n", { plain = true })
      state.suggestion = lines
      state.last = { prompt = prompt, suggestion = lines }
      screen.show_ghost(pos, state.suggestion)
      log_event(conf, string.format("ok lines=%d file=%s", #lines, relpath(vim.api.nvim_buf_get_name(buf))))
    end)
  end)
  if conf.timeout_ms and conf.timeout_ms > 0 then
    state.job_timer = vim.defer_fn(function()
      if state.job then
        log_event(conf, "timeout; killing job")
        cancel_pending("Codex ghost timed out")
      end
    end, conf.timeout_ms)
  end
end

function M.dismiss()
  reset()
end

function M.accept()
  screen.insert_lines(state.pos, state.suggestion)
  reset()
end

function M.request(opts)
  run_request(vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1] - 1, vim.api.nvim_win_get_cursor(0)[2], vim.tbl_extend("force", state.config, opts or {}))
end

function M.show_last()
  if not state.last then
    vim.notify("Codex ghost: no history", vim.log.levels.INFO)
    return
  end
  vim.notify(table.concat(state.last.suggestion, "\\n"), vim.log.levels.INFO)
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
  state.config = config.setup(opts)
  screen.setup()

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
