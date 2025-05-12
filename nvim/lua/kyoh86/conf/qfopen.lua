vim.api.nvim_create_autocmd("QuickfixCmdPost", {
  pattern = "*",
  callback = function()
    local qf_list = vim.fn.getqflist()
    if #qf_list > 0 then
      vim.cmd.copen()
    end
  end,
})
