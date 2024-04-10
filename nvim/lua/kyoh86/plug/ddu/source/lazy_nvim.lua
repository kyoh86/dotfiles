local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-lazy_nvim",
  dependencies = { "ddu.vim", "ddu-kind-file", "lazy.nvim" },
  config = helper.setup_func("lazy_nvim", {
    sources = { { name = "lazy_nvim" } },
    kindOptions = {
      file = {
        defaultAction = "cd",
      },
    },
    actionParams = {
      browse = { opener = "wslview" },
    },
  }, {
    start = {
      key = "<leader><leader>p",
      desc = "lazy.nvim プラグイン",
    },
    filelike = true,
    localmap = {
      ["<leader>e"] = { action = "itemAction", params = { name = "open" } },
      ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
      ["<leader>g"] = { action = "itemAction", params = { name = "grep_config" } },
      ["<leader>c"] = { action = "itemAction", params = { name = "grep_config" } },
      ["<leader>f"] = { action = "itemAction", params = { name = "clone" } },
    },
  }),
}
return spec
