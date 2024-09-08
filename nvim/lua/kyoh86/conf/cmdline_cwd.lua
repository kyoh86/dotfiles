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

local f = require("kyoh86.lib.func")
vim.keymap.set("c", "<C-x>t", f.bind_all(inscmdline, vim.fn.expand("%:t")))
vim.keymap.set("c", "<C-x>p", f.bind_all(inscmdline, vim.fn.expand("%:p")))
vim.keymap.set("c", "<C-x>pp", f.bind_all(inscmdline, vim.fn.expand("%:p")))
vim.keymap.set("c", "<C-x>ph", f.bind_all(inscmdline, vim.fn.expand("%:p:h")))
vim.keymap.set("c", "<C-x>h", f.bind_all(inscmdline, vim.fn.expand("%:h")))
