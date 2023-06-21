--- ハイライトや色の設定
return {
  "kyoh86/momiji",
  priority = 1000,
  config = function()
    vim.cmd([[
        syntax enable
        colorscheme momiji
    ]])
  end,
}
