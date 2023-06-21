local M = {}

---call :stopinsert and call back when the mode changed
---@param callback fun()
function M.stopInsert(callback)
  if vim.fn.mode() ~= "i" then
    callback()
  end
  vim.api.nvim_create_autocmd("InsertLeave", {
    once = true,
    callback = callback,
  })
  vim.cmd.stopinsert()
end

---call :startinsert and call back when the mode changed
---@param callback fun()
function M.startInsert(callback)
  if vim.fn.mode() == "i" then
    callback()
  end
  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = "*:i",
    once = true,
    callback = callback,
  })
  vim.cmd.startinsert()
end

---call :startinsert! (to start insert at EOL) and call back when the mode changed
---@param callback fun()
function M.startInsertAtEOL(callback)
  if vim.fn.mode() == "i" then
    callback()
  end
  vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = "*:i",
    once = true,
    callback = callback,
  })
  vim.cmd.startinsert({ bang = true })
end

return M
