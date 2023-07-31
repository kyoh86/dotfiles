local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-github",
  dependencies = { "Shougo/ddu.vim" },
  config = function()
    kyoh86.fa.ddu.custom.patch_global({
      kindOptions = {
        github_issue = {
          defaultAction = "open",
        },
      },
    })
    helper.map_start("<leader>fgi", {
      name = "github-issues",
      sources = { {
        name = "github_repo_issue",
        params = { source = "cwd" },
      } },
    })
    helper.map_ff("github-issues", {
      ["<leader>e"] = { action_name = "itemAction", params = { name = "edit" } },
    })
    helper.map_start("<leader>fgp", {
      name = "github-pulls",
      sources = { {
        name = "github_repo_pull",
        params = { source = "cwd" },
      } },
    })
    helper.map_ff("github-pulls", {
      ["<leader>e"] = { action_name = "itemAction", params = { name = "edit" } },
    })
  end,
}
return spec
