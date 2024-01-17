local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-docbase",
  dependencies = { "ddu.vim", "denops-docbase.vim" },
  config = helper.setup_func("docbase_posts", {
    sources = { { name = "docbase_posts", params = { domain = "wacul" } } },
    kindOptions = {
      file = {
        defaultAction = "open",
      },
    },
  }, {
    start = {
      key = "<leader>fd",
      desc = "DocBase",
    },
    filelike = true,
    localmap = {
      ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
    },
  }),
}
return spec
