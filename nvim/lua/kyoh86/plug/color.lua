--- ハイライトや色の設定
---@type LazySpec
local spec = {
  "kyoh86/momiji",
  priority = 1000,
  config = function()
    vim.cmd.syntax("enable")
    vim.cmd.colorscheme("momiji")
  end,
}
return spec
