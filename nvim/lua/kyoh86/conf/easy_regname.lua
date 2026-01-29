--- Original Author: atusy
--- Cite: https://blog.atusy.net/2023/12/17/vim-easy-to-remember-regnames/
local au = require("kyoh86.lib.autocmd")
au.group("kyoh86.conf.easy_regname", true):hook("TextYankPost", {
  callback = function()
    if vim.v.event.regname == "" then
      vim.fn.setreg(vim.v.event.operator, vim.fn.getreg())
    end
  end,
})
