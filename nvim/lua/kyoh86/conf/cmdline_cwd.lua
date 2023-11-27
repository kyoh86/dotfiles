--- Insert text at cursor in the cmdline
---@param ins string  Inserting text
local function inscmdline(ins)
  local cmd = vim.fn.getcmdline()
  local pos = vim.fn.getcmdpos()
  local left = ""
  local right = ""
  if cmd ~= nil and pos ~= nil and pos > 0 then
    left = cmd:sub(1, pos - 1)
    right = cmd:sub(pos)
  end
  vim.fn.setcmdline(left .. ins .. right, pos + #ins)
end

vim.keymap.set("c", "<C-x>t", function()
  inscmdline(vim.fn.expand("%:t")--[[@as string]])
end)

vim.keymap.set("c", "<C-x>p", function()
  inscmdline(vim.fn.expand("%:p")--[[@as string]])
end)

vim.keymap.set("c", "<C-x>pp", function()
  inscmdline(vim.fn.expand("%:p")--[[@as string]])
end)

vim.keymap.set("c", "<C-x>ph", function()
  inscmdline(vim.fn.expand("%:p:h")--[[@as string]])
end)

vim.keymap.set("c", "<C-x>h", function()
  inscmdline(vim.fn.expand("%:h")--[[@as string]])
end)
