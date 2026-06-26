local tmux = require("kyoh86.lib.tmux")

local M = {}

local function split_lines(text)
  local lines = vim.split(text or "", "\n", { plain = true })
  if #lines > 1 and lines[#lines] == "" then
    table.remove(lines)
  end
  if #lines == 0 then
    return { "" }
  end
  return lines
end

local function capture_name(data)
  local pane = data.pane or "pane"
  local timestamp = os.date("%Y%m%dT%H%M%S")
  return ("tmux://%s/%s-%s"):format(pane, timestamp, vim.uv.hrtime())
end

function M.open(data)
  data = data or {}
  local lines = split_lines(data.text)
  for r = #lines, 1, -1 do
    if lines[r] == "" then
      table.remove(lines, r)
    end
  end

  vim.cmd.tabnew()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, capture_name(data))
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "tmux-capture"

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false

  if data.cwd ~= nil and data.cwd ~= "" then
    pcall(vim.cmd.lcd, vim.fn.fnameescape(data.cwd))
  end

  vim.api.nvim_win_set_cursor(0, { #lines, 0 })
  tmux.focus_nvim_pane()
end

return M
