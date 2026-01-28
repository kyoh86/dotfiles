local M = {}

local config = require("kyoh86.poc.ghost.config")
local Agent = require("kyoh86.poc.ghost.agent")
local Preview = require("kyoh86.poc.ghost.preview")
local Target = require("kyoh86.poc.ghost.target")

--- @class kyoh86.poc.ghost.State
--- @field config kyoh86.poc.ghost.Config
--- @field agent kyoh86.poc.ghost.Agent
--- @field preview kyoh86.poc.ghost.Preview
local state = {}

local function should_skip(buf)
  if not state.config then
    return true, "plugin not setup"
  end
  local ft = vim.bo[buf].filetype
  local bt = vim.bo[buf].buftype
  if vim.list_contains(state.config.disable_buftypes, bt) then
    return true, "buftype disabled"
  end
  if vim.list_contains(state.config.disable_filetypes, ft) then
    return true, "filetype disabled"
  end
  if vim.bo[buf].readonly then
    return true, "buffer is readonly"
  end
  if vim.api.nvim_buf_line_count(buf) > state.config.max_lines then
    return true, "buffer is too large"
  end
  return false
end

function M.request()
  local buf = vim.api.nvim_get_current_buf()
  local skip, reason = should_skip(buf)
  if skip then
    vim.notify("Ghost: skipped, " .. reason, vim.log.levels.INFO)
    return
  end

  local win = vim.api.nvim_get_current_win()
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  row = row - 1 -- 0-based

  local target = Target.new(buf, row, col, state.config)
  local context = target:context()

  if not context then
    vim.notify("Ghost: no context to send", vim.log.levels.INFO)
    return
  end

  vim.notify("Ghost: requesting suggestion...", vim.log.levels.INFO)
  state.agent:request(context, function(_, suggestion)
    local function accept()
      local err = target:apply(suggestion)
      if err then
        vim.notify("Ghost apply failed: " .. err, vim.log.levels.ERROR)
      else
        vim.notify("Ghost applied", vim.log.levels.INFO)
      end
    end
    local function deny()
      vim.notify("Ghost suggestion denied", vim.log.levels.INFO)
    end
    state.preview:show(context, suggestion, accept, deny)
  end)
end

function M.setup(opts)
  state.config = config.setup(opts)
  state.agent = Agent.new(state.config)
  state.preview = Preview.new()

  vim.api.nvim_create_user_command("Ghost", M.request, {})
end

return M
