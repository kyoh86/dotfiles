local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-docbase",
  dependencies = { "ddu.vim", "denops-docbase.vim" },
  config = function()
    helper.setup("docbase_posts", {
      sources = { { name = "docbase_posts", params = { domain = "wacul" } } },
      kindOptions = {
        file = {
          defaultAction = "open",
        },
      },
    }, {
      startkey = "<leader>fd",
      filelike = true,
      localmap = {
        ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
      },
    })
  end,
}
return spec
