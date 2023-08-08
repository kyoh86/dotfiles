local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-github",
  dependencies = { "ddu.vim" },
  config = function()
    kyoh86.fa.ddu.custom.patch_global({
      kindOptions = {
        github_issue = {
          defaultAction = "open",
        },
        github_repo = {
          defaultAction = "open",
        },
      },
    })

    local map = {
      ["<leader>e"] = { action = "itemAction", params = { name = "edit" } },
      ["<leader>c"] = { action = "itemAction", params = { name = "checkout" } },
    }
    helper.setup("github-issues", {
      sources = { {
        name = "github_repo_issue",
        params = { source = "cwd" },
      } },
    }, {
      startkey = "<leader>fgi",
      localmap = map,
    })
    helper.setup("github-pulls", {
      sources = { {
        name = "github_repo_pull",
        params = { source = "cwd" },
      } },
    }, {
      startkey = "<leader>fgp",
      localmap = map,
    })
    vim.api.nvim_create_user_command("DduSources", function()
      kyoh86.fa.ddu.start({
        sources = { {
          name = "github_search_repo",
          params = { query = "topic:ddu-source" },
        } },
      })
    end, {})
    vim.api.nvim_create_user_command("DduFilters", function()
      kyoh86.fa.ddu.start({
        sources = { {
          name = "github_search_repo",
          params = { query = "topic:ddu-filter" },
        } },
      })
    end, {})
    vim.api.nvim_create_user_command("DduKinds", function()
      kyoh86.fa.ddu.start({
        sources = { {
          name = "github_search_repo",
          params = { query = "topic:ddu-kind" },
        } },
      })
    end, {})
  end,
}
return spec
