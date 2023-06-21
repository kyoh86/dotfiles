--- ヘルプの見た目変更
if vim.opt_local.buftype:get() ~= "help" then
  --- インデント設定
  local indent_size = 8
  vim.opt_local.tabstop = indent_size
  vim.opt_local.shiftwidth = indent_size
  vim.opt_local.expandtab = false

  vim.opt_local.colorcolumn = { 80 }
  vim.opt_local.textwidth = 80

  vim.api.nvim_set_hl(0, "helpIgnore", { link = "PreProc" })
  vim.api.nvim_set_hl(0, "helpBar", { link = "PreProc" })
  vim.api.nvim_set_hl(0, "helpStar", { link = "PreProc" })
  vim.api.nvim_set_hl(0, "helpBacktick", { link = "PreProc" })
  if vim.fn.has("conceal") == 1 then
    vim.opt_local.conceallevel = 0
  end

  -- vim.opt.formatexpr = tostring(vim.fa.autofmt.japanese.formatexpr())
  vim.g.autofmt_allow_over_tw = 1
  vim.opt_local.formatoptions:append({ "m", "B" })
  vim.opt_local.smartindent = true
end
