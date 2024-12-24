require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
  kyoh86.ensure(colors_name, function(m)
    vim.cmd(string.format(
      [[
    highlight DiagnosticFloatingOk    guibg=%s ctermbg=%s guifg=%s ctermfg=%s
    highlight DiagnosticFloatingHint  guibg=%s ctermbg=%s guifg=%s ctermfg=%s
    highlight DiagnosticFloatingInfo  guibg=%s ctermbg=%s guifg=%s ctermfg=%s
    highlight DiagnosticFloatingWarn  guibg=%s ctermbg=%s guifg=%s ctermfg=%s
    highlight DiagnosticFloatingError guibg=%s ctermbg=%s guifg=%s ctermfg=%s
  ]],
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.brightgreen.gui,
      m.palette.brightgreen.cterm,
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.gradation3.gui,
      m.palette.gradation3.cterm,
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.brightblue.gui,
      m.palette.brightblue.cterm,
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.brightred.gui,
      m.palette.brightred.cterm,
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.red.gui,
      m.palette.red.cterm
    ))
  end)
end, true)

-- 随時表示されるDiagnosticsの設定
vim.diagnostic.config({
  underline = true,
  update_in_insert = true,
  virtual_text = {
    severity = vim.diagnostic.severity.WARN,
    source = true,
  },
  float = {
    focusable = true,
    border = "rounded",
    header = {},
    source = true,
    scope = "line",
  },
  signs = true,
  severity_sort = true,
})
