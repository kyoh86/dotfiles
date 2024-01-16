---@type LazySpec
local spec = {
  "folke/which-key.nvim",
  config=function()
    require("which-key").setup()
  end,
}
return spec
