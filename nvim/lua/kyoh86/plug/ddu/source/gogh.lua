local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-gogh",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file" },
  config = function()
    helper.map_start("<leader>fpl", "gogh_project", {
      sources = { { name = "gogh_project" } },
      kindOptions = {
        gogh_project = {
          defaultAction = "cd",
        },
      },
    })
    helper.map_ff_file("gogh_project", function(map)
      map("<leader>e", helper.action("itemAction", { name = "open" }))
      map("<leader>b", helper.action("itemAction", { name = "browse" }))
    end)

    helper.map_start("<leader>fpr", "gogh_repo", {
      sources = { { name = "gogh_repo" } },
      kindOptions = {
        gogh_repo = {
          defaultAction = "browse",
        },
      },
    })

    helper.map_ff("gogh_repo", function(map)
      map("<leader>g", helper.action("itemAction", { name = "get" }))
    end)
  end,
}
return spec
