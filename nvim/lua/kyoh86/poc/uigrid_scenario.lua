vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
}, { confirm = false })

vim.cmd("enew")
vim.fn.setline(1, "hello from scenario")
