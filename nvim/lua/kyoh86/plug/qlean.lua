---@type LazySpec
local spec = {
  "kyoh86/qlean.nvim",
  config = function()
    local rule = require("qlean.rule")
    require("qlean").setup({
      keep = rule.any(rule.buftype("", "acwrite", "terminal"), rule.filetype("fern")),
    })
  end,
}
return spec
