local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-github",
  config = function()
    kyoh86.fa.ddu.custom.patch_global({
      kindOptions = {
        github_issue = {
          defaultAction = "open",
        },
      },
    })
    helper.map_start("<leader>fgh", "github-issues", function()
      return {
        sources = { {
          name = "github_repo_issue",
          params = { source = "cwd" },
        } },
      }
    end)
  end,
}
return spec
