local M = {}

--- @class codex_ghost.Preview Preview handler
--- @field show fun(self: codex_ghost.Preview, accept:fun(), deny:fun(), filename:string, filetype:string, suggestion:string[])

--- @return codex_ghost.Preview
function M.new()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  local instance = {
    queue = {},
    buf = buf,
    win = nil,
    current_item = nil,
  }
  setmetatable(instance, { __index = M })
  instance:setup()
  return instance
end

--- @private
function M:handle_accept()
  if #self.queue == 0 or self.queue[1] ~= self.current_item then
    return false
  end
  local item = table.remove(self.queue, 1)
  item.accept()
  self.current_item = nil
  return true
end

--- @private
function M:handle_deny()
  if #self.queue == 0 or self.queue[1] ~= self.current_item then
    return false
  end
  local item = table.remove(self.queue, 1)
  item.deny()
  self.current_item = nil
  return true
end

--- @private
function M:setup()
  local function accept_and_close()
    if self:handle_accept() then
      self:close()
    end
  end
  vim.keymap.set("n", "<CR>", accept_and_close, { buffer = self.buf, silent = true, nowait = true })
  vim.keymap.set("n", "a", accept_and_close, { buffer = self.buf, silent = true, nowait = true })
  vim.keymap.set("n", "q", function()
    self:close()
  end, { buffer = self.buf, silent = true, nowait = true })

  local group = vim.api.nvim_create_augroup("CodexGhostPreview", { clear = true })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = self.buf,
    callback = vim.schedule_wrap(function()
      if self:handle_deny() and #self.queue > 0 then
        self:process()
      end
    end),
  })
end

--- @private
function M:close()
  if vim.api.nvim_win_is_valid(self.win) then
    pcall(vim.api.nvim_win_close, self.win, true)
  end
  self.win = nil
end

--- @param accept fun()
--- @param deny fun()
--- @param filename string
--- @param filetype string
--- @param suggestion string[]
function M:show(accept, deny, filename, filetype, suggestion)
  table.insert(self.queue, { accept = accept, deny = deny, filename = filename, filetype = filetype, suggestion = suggestion })
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    -- Do not open a new window if one is already visible.
    -- The new item will be processed when the current one is closed.
    return
  end
  self:process()
end

--- @private
function M:write()
  local entry = self.queue[1]
  vim.api.nvim_set_option_value("modifiable", true, { buf = self.buf })
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {
    "Codex suggestion",
    string.format("File: %s", entry.filename),
    "Apply: <CR>/a | Close: q",
    "",
    string.format("``````%s", entry.filetype),
  })
  vim.api.nvim_buf_set_lines(self.buf, -1, -1, false, entry.suggestion)
  vim.api.nvim_buf_set_lines(self.buf, -1, -1, false, { "``````" })
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
  return #entry.suggestion + 6
end

--- @private
function M:process()
  self.current_item = self.queue[1]
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
