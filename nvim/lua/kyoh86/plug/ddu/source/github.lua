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

    local map = {
      ["<leader>e"] = { action = "itemAction", params = { name = "edit" } },
    }
    helper.setup("github-issues", {
      sources = { {
        name = "github_repo_issue",
        params = { source = "cwd" },
      } },
    }, {
      startkey = "<leader>fgp",
      localmap = map,
    })
    helper.setup("github-pulls", {
      sources = { {
        name = "github_repo_pull",
        params = { source = "cwd" },
      } },
    }, {
      startkey = "<leader>fgi",
      localmap = map,
    })
  end,
}
return spec
