local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-docbase",
  dependencies = { "ddu.vim" },
  config = function()
    helper.setup("docbase_posts", {
      sources = { { name = "docbase_posts", params = { domain = "wacul" }, options = { sorters = { "sorter_docbase_post" } } } },
      kindOptions = {
        file = {
          defaultAction = "open",
        },
      },
    }, {
      start = {
        key = "<leader>fdp",
        desc = "DocBase Posts",
      },
      filelike = true,
      localmap = {
        ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
      },
    })
    helper.setup("docbase_templates", {
      sources = { { name = "docbase_templates", params = { domain = "wacul" }, options = { sorters = { "sorter_docbase_post" } } } },
      kindOptions = {
        file = {
          defaultAction = "open",
        },
      },
    }, {
      start = {
        key = "<leader>fdt",
        desc = "DocBase Templates",
      },
      filelike = true,
      localmap = {
        ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
      },
    })
  end,
}
return spec
