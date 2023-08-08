local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-lazy_nvim",
  dependencies = { "ddu.vim", "ddu-kind-file", "lazy.nvim" },
  config = function()
    helper.setup("lazy_nvim", {
      sources = { { name = "lazy_nvim" } },
      kindOptions = {
        file = {
          defaultAction = "cd",
        },
      },
    }, {
      startkey = "<leader><leader>p",
      filelike = true,
      localmap = {
        ["<leader>e"] = { action = "itemAction", params = { name = "open" } },
        ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
        ["<leader>g"] = { action = "itemAction", params = { name = "grep_config" } },
        ["<leader>c"] = { action = "itemAction", params = { name = "grep_config" } },
        ["<leader>f"] = { action = "itemAction", params = { name = "fork" } },
      },
    })
  end,
}
return spec
