local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-lazy_nvim",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "folke/lazy.nvim" },
  config = function()
    helper.map_start("<leader><leader>p", "lazy_nvim", {
      sources = { { name = "lazy_nvim" } },
      kindOptions = {
        file = {
          defaultAction = "cd",
        },
      },
    })
    helper.map_ff_file("lazy_nvim", function(map)
      map("<leader>e", helper.action("itemAction", { name = "open" }))
      map("<leader>b", helper.action("itemAction", { name = "browse" }))
      map("<leader>g", helper.action("itemAction", { name = "grep_config" }))
      map("<leader>c", helper.action("itemAction", { name = "grep_config" }))
      map("<leader>f", helper.action("itemAction", { name = "fork" }))
    end)
  end,
}
return spec
