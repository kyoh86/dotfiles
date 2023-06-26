--- Insert text at cursor in the cmdline
local function inscmdline(ins)
  local cmd = vim.fn.getcmdline()
  local pos = vim.fn.getcmdpos()
  local left = cmd:sub(1, pos - 1)
  local right = cmd:sub(pos)
  vim.fn.setcmdline(left .. ins .. right, pos + #ins)
end

vim.keymap.set("c", "<C-p>t", function()
  inscmdline(vim.fn.expand("%:p:t"))
end)

vim.keymap.set("c", "<C-p>p", function()
  inscmdline(vim.fn.expand("%:p"))
end)

vim.keymap.set("c", "<C-p>h", function()
  inscmdline(vim.fn.expand("%:p:h"))
end)
