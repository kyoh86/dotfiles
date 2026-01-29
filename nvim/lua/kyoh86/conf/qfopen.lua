local au = require("kyoh86.lib.autocmd")
au.group("kyoh86.conf.qfopen", true):hook("QuickFixCmdPost", {
  pattern = "*",
  callback = function()
    local qf_list = vim.fn.getqflist()
    if #qf_list > 0 then
      vim.cmd.copen()
    end
  end,
})
