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
    helper.map_ff_file("lazy_nvim", {
      ["<leader>e"] = { "itemAction", name = "open" },
      ["<leader>b"] = { "itemAction", name = "browse" },
      ["<leader>g"] = { "itemAction", name = "grep_config" },
      ["<leader>c"] = { "itemAction", name = "grep_config" },
      ["<leader>f"] = { "itemAction", name = "fork" },
    })
  end,
}
return spec
