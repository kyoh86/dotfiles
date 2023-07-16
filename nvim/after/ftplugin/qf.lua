--- quickfix

local function cc_vsp()
  local error_nr = vim.fn.line(".")
  vim.cmd.wincmd("k")
  vim.cmd.wincmd("v")
  vim.cmd.cc(error_nr)
end

vim.keymap.set("n", "<leader>h", "<c-w><cr>", { remap = false, buffer = true })
vim.keymap.set("n", "<leader>x", "<c-w><cr>", { remap = false, buffer = true })
vim.keymap.set("n", "<leader>v", cc_vsp, { remap = false, buffer = true })
