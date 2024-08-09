vim.opt.clipboard = ""

vim.keymap.set({ "n", "x" }, "gd", '"*d')
vim.keymap.set({ "n", "x" }, "gy", '"*y')
vim.keymap.set({ "n", "x" }, "gp", '"*p')
vim.keymap.set({ "n", "x" }, "gP", '"*P')
vim.keymap.set({ "n", "x" }, "g_", '"*_', { remap = true })

if vim.g.kyoh86_setup_clipboard ~= 1 then
  kyoh86.glaze("clipboard", function()
    if vim.fn.executable("win32yank.exe") ~= 0 then
      return "win32"
    elseif vim.fn.executable("wl-copy") ~= 0 and vim.fn.executable("wl-paste") ~= 0 then
      return "wlcopy"
    end
    return ""
  end)
end
