local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-gogh",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file" },
  config = function()
    local name_proj = "gogh-project"
    helper.map_start("<leader>fpl", {
      name = name_proj,
      sources = { { name = "gogh_project" } },
      kindOptions = {
        gogh_project = {
          defaultAction = "cd",
        },
      },
    })
    helper.map_ff_file(name_proj, {
      ["<leader>e"] = { action_name = "itemAction", params = { name = "open" } },
      ["<leader>b"] = { action_name = "itemAction", params = { name = "browse" } },
    })

    local name_repo = "gogh-repo"
    helper.map_start("<leader>fpr", {
      name = name_repo,
      sources = { { name = "gogh_repo" } },
      kindOptions = {
        gogh_repo = {
          defaultAction = "browse",
        },
      },
    })

    helper.map_ff(name_repo, {
      ["<leader>g"] = { action_name = "itemAction", params = { name = "get" } },
    })
  end,
}
return spec
