local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-inkdrop",
  dependencies = { "ddu.vim", "kyoh86/denops-inkdrop.vim" },
  config = function()
    helper.setup("inkdrop_note", {
      sources = { { name = "inkdrop_note" } },
      kindOptions = {
        inkdrop_note = {
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

    helper.setup("inkdrop_book", {
      sources = { { name = "inkdrop_book" } },
      kindOptions = {
        inkdrop_book = {
          defaultAction = "open",
        },
      },
    }, {
      start = {
        key = "<leader>fib",
        desc = "Inkdrop Books",
      },
      filelike = true,
      localmap = {
        ["<leader>a"] = { action = "itemAction", params = { name = "moveNoteToBook" } },
      },
    })

    helper.setup("inkdrop_tag", {
      sources = { { name = "inkdrop_tag" } },
      kindOptions = {
        inkdrop_tag = {
          defaultAction = "open",
        },
      },
    }, {
      start = {
        key = "<leader>fit",
        desc = "Inkdrop Tags",
      },
      filelike = true,
      localmap = {
        ["<leader>a"] = { action = "itemAction", params = { name = "addTag" } },
        ["<leader>d"] = { action = "itemAction", params = { name = "removeTag" } },
      },
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
      localmap = {
        ["<leader>a"] = { action = "itemAction", params = { name = "setStatus" } },
      },
    })
  end,
}

return spec
