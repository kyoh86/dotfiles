local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-gogh",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file" },
  config = function()
    helper.start_by("<leader>fpl", "gogh_project", {
      sources = { { name = "gogh_project" } },
      kindOptions = {
        gogh_project = {
          defaultAction = "cd",
        },
      },
    })
    helper.map_for_file("gogh_project")

    helper.start_by("<leader>fpr", "gogh_repo", {
      sources = { { name = "gogh_repo" } },
      kindOptions = {
        gogh_repo = {
          defaultAction = "browse",
        },
      },
    })

    helper.ff_map("gogh_repo", function(map)
      map("<leader>g", helper.action("itemAction", { name = "get" }))
    end)
  end,
}
return spec
