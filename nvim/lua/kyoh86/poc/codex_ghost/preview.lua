local M = {}

--- @class codex_ghost.Preview Preview handler
--- @field show fun(accept:fun(), deny:fun(), filename:string, filetype:string, suggestion:string[])

--- @return codex_ghost.Preview
function M.new()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  local instance = {
    queue = {},
    processing = false,
    buf = buf,
    win = nil,
  }
  setmetatable(instance, M)
  instance:setup()
  return instance
end

--- @private
function M:setup()
  vim.keymap.set("n", "<CR>", function()
    self:accept()
  end, { buffer = self.buf, silent = true })
  vim.keymap.set("n", "a", function()
    self:accept()
  end, { buffer = self.buf, silent = true })
  vim.keymap.set("n", "q", function()
    self:deny()
  end, { buffer = self.buf, silent = true })
  -- TODO: WinBufLeave -> self:deny()
end

--- @private
function M:close()
  if vim.api.nvim_win_is_valid(self.win) then
    pcall(vim.api.nvim_win_close, self.win, true)
  end
  self.win = nil
end

--- @private
function M:accept()
  if #self.queue < 1 then
    return
  end
  self.queue[1].accept()
  table.remove(self.queue, 1)
  self:close()
  if #self.queue > 0 then
    self:process()
  end
end

--- @private
function M:deny()
  if #self.queue < 1 then
    return
  end
  self.queue[1].deny()
  table.remove(self.queue, 1)
  self:close()
  if #self.queue > 0 then
    self:process()
  end
end

--- @param accept fun()
--- @param deny fun()
--- @param filename string
--- @param filetype string
--- @param suggestion string[]
function M:show(accept, deny, filename, filetype, suggestion)
  table.insert(self.queue, { accept = accept, deny = deny, filename = filename, filetype = filetype, suggestion = suggestion })
  if #self.queue > 1 then
    return
  end
  self:process()
end

--- @private
function M:write()
  local entry = self.queue[1]
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {
    "Codex suggestion",
    string.format("File: %s", entry.filename),
    "Apply: <CR>/a | Close: q",
    "",
    string.format("``````%s", entry.filetype),
  })
  vim.api.nvim_buf_set_lines(self.buf, -1, -1, false, entry.suggestion)
  vim.api.nvim_buf_set_lines(self.buf, -1, -1, false, { "``````" })

  return #entry.suggestion + 6
end

--- @private
function M:process()
  local lines = self:write()

  local width = math.min(math.max(40, math.floor(vim.o.columns * 0.6)), vim.o.columns)
  local height = math.min(lines, math.max(6, math.floor(vim.o.lines * 0.6)))
  local win = vim.api.nvim_open_win(self.buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = "single",
  })
  self.win = win
end

return M
