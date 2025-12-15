local M = {}

--- @class codex_ghost.Preview Preview handler
--- @field show fun(self: codex_ghost.Preview, context: codex_ghost.Context, suggestion:string[], accept:fun(), deny:fun())
--- @field buf integer

--- @return codex_ghost.Preview
function M.new()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  local instance = {
    queue = {},
    buf = buf,
    win = nil,
  }
  setmetatable(instance, { __index = M })
  instance:setup()
  return instance
end

--- @private
function M:handle_accept()
  local item = table.remove(self.queue, 1)
  item.accept()
end

--- @private
function M:handle_deny()
  local item = table.remove(self.queue, 1)
  item.deny()
end

--- @private
function M:setup()
  local function accept_and_close()
    self:handle_accept()
    self:close()
  end
  local function deny_and_close()
    self:handle_deny()
    self:close()
  end
  vim.keymap.set("n", "<CR>", accept_and_close, { buffer = self.buf, silent = true, nowait = true })
  vim.keymap.set("n", "a", accept_and_close, { buffer = self.buf, silent = true, nowait = true })
  vim.keymap.set("n", "q", deny_and_close, { buffer = self.buf, silent = true, nowait = true })
  vim.keymap.set("n", "<ESC>", deny_and_close, { buffer = self.buf, silent = true, nowait = true })

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

--- @param context codex_ghost.Context
--- @param suggestion string[]
--- @param accept fun()
--- @param deny fun()
function M:show(context, suggestion, accept, deny)
  table.insert(self.queue, { context = context, suggestion = suggestion, accept = accept, deny = deny })
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    -- Do not open a new window if one is already visible.
    -- The new item will be processed when the current one is closed.
    return
  end
  self:process()
end

--- @param self codex_ghost.Preview
--- @param lines string[]
--- @param replace? boolean
function M:put_lines(lines, replace)
  vim.api.nvim_buf_set_lines(self.buf, replace and 0 or -1, -1, false, lines)
end

--- @private
function M:write()
  local cur = self.queue[1]
  vim.api.nvim_set_option_value("modifiable", true, { buf = self.buf })
  self:put_lines({
    "Codex suggestion",
    string.format("File: %s", cur.context.filename),
    "Apply: <CR>/a | Close: <ESC>/q",
    "",
    "``````diff",
  }, true)
  self:put_lines(vim.tbl_map(function(v)
    return " " .. v
  end, vim.list_slice(cur.context.before, #cur.context.before - 1, #cur.context.before)))
  self:put_lines({ " " .. cur.context.line })
  self:put_lines(vim.tbl_map(function(v)
    return "+" .. v
  end, cur.suggestion))
  self:put_lines(vim.tbl_map(function(v)
    return " " .. v
  end, vim.list_slice(cur.context.after, 1, 3)))
  self:put_lines({ "``````" })
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
  return #cur.suggestion + 6 + 6
end

--- @private
function M:process()
  local lines = self:write()

  local width = math.min(math.max(40, math.floor(vim.o.columns * 0.9)), vim.o.columns)
  local height = math.min(lines, math.max(6, math.floor(vim.o.lines * 0.9)))
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
