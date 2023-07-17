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
      ["<leader>e"] = { action_name = "itemAction", params = { name = "open" } },
      ["<leader>b"] = { action_name = "itemAction", params = { name = "browse" } },
      ["<leader>g"] = { action_name = "itemAction", params = { name = "grep_config" } },
      ["<leader>c"] = { action_name = "itemAction", params = { name = "grep_config" } },
      ["<leader>f"] = { action_name = "itemAction", params = { name = "fork" } },
    })
  end,
}
return spec
