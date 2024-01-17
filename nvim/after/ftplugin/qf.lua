--- quickfix

local function cc_vsp()
  local error_nr = vim.fn.line(".")
  vim.cmd.wincmd("k")
  vim.cmd.wincmd("v")
  vim.cmd([[cc ]] .. error_nr)
end

vim.keymap.set("n", "<leader>h", "<c-w><cr>", { remap = false, buffer = true, desc = "水平分割して開く" })
vim.keymap.set("n", "<leader>x", "<c-w><cr>", { remap = false, buffer = true, desc = "水平分割して開く" })
vim.keymap.set("n", "<leader>v", cc_vsp, { remap = false, buffer = true, desc = "垂直分割して開く" })
