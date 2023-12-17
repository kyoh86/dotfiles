--- Original Author: atusy
--- Cite: https://blog.atusy.net/2023/12/17/vim-easy-to-remember-regnames/
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("use-easy-regname", {}),
  callback = function()
    if vim.v.event.regname == "" then
      vim.fn.setreg(vim.v.event.operator, vim.fn.getreg())
    end
  end,
})
