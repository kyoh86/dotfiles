vim.opt.clipboard = ""
vim.g.clipboard = {
  name = "win32yank-wsl",
  copy = {
    ["+"] = "win32yank.exe -i --crlf",
    ["*"] = "win32yank.exe -i --crlf",
  },
  paste = {
    ["+"] = "win32yank.exe -o --lf",
    ["*"] = "win32yank.exe -o --lf",
  },
  cache_enabled = 1,
}
vim.keymap.set({ "n", "x" }, "gd", '"*d')
vim.keymap.set({ "n", "x" }, "gy", '"*y')
vim.keymap.set({ "n", "x" }, "gp", '"*p')
vim.keymap.set({ "n", "x" }, "gP", '"*P')
