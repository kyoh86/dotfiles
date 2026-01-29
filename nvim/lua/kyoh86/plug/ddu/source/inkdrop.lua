local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-inkdrop",
  dev = true,
  dependencies = { "ddu.vim", "kyoh86/denops-inkdrop.vim" },
  config = function()
    helper.setup("inkdrop_notes", {
      sources = { { name = "inkdrop_notes" } },
      kindOptions = {
        file = {
          defaultAction = "open",
        },
      },
    }, {
      start = {
        key = "<leader>fin",
        desc = "Inkdrop Notes",
      },
      filelike = true,
    })

    helper.setup("inkdrop_books", {
      sources = { { name = "inkdrop_books" } },
      kindOptions = {
        file = {
          defaultAction = "open",
        },
      },
    }, {
      start = {
        key = "<leader>fib",
        desc = "Inkdrop Books",
      },
      filelike = true,
    })

    helper.setup("inkdrop_tags", {
      sources = { { name = "inkdrop_tags" } },
      kindOptions = {
        file = {
          defaultAction = "open",
        },
      },
    }, {
      start = {
        key = "<leader>fit",
        desc = "Inkdrop Tags",
      },
      filelike = true,
    })

    helper.setup("inkdrop_status", {
      sources = { { name = "inkdrop_status" } },
      kindOptions = {
        inkdrop_menu = {
          defaultAction = "open",
        },
      },
    }, {
      start = {
        key = "<leader>fis",
        desc = "Inkdrop Status",
      },
    })
  end,
}

return spec
