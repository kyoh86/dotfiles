local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-gogh",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file" },
  config = function()
    helper.setup("gogh-project", {
      sources = { { name = "gogh_project" } },
      kindOptions = {
        gogh_project = {
          defaultAction = "cd",
        },
      },
    }, {
      startkey = "<leader>fpl",
      filelike = true,
      localmap = {
        ["<leader>e"] = { action = "itemAction", params = { name = "open" } },
        ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
      },
    })

    helper.setup("gogh-repo", {
      sources = { { name = "gogh_repo" } },
      kindOptions = {
        gogh_repo = {
          defaultAction = "browse",
        },
      },
    }, {
      startkey = "<leader>fpr",
      localmap = {
        ["<leader>g"] = { action = "itemAction", params = { name = "get" } },
      },
    })
  end,
}
return spec
