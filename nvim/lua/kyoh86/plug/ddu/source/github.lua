local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-github",
  dependencies = { "ddu.vim" },
  config = function()
    vim.fn["ddu#custom#patch_global"]({
      kindOptions = {
        github_pull = {
          defaultAction = "open",
        },
        github_issue = {
          defaultAction = "open",
        },
        github_repo = {
          defaultAction = "open",
        },
      },
    })

    local format = "${this.html_url.replace(/^https:\\/\\/[^\\/]+\\/([^\\/]+)\\/([^\\/]+)\\/(?:issues|pull)\\/(\\d+)/, '$1/$2#$3')}"
    local map = {
      ["<leader>e"] = { action = "itemAction", params = { name = "edit" } },
      ["<leader>c"] = { action = "itemAction", params = { name = "checkout" } },
      ["<leader>p"] = { action = "itemAction", params = { name = "append", params = { format = format, avoid = "filename" } } },
      ["<leader>P"] = { action = "itemAction", params = { name = "insert", params = { format = format, avoid = "filename" } } },
    }
    helper.setup("github-issues", {
      sources = { {
        name = "github_repo_issue",
        params = { source = "cwd" },
      } },
    }, {
      start = {
        key = "<leader>fgi",
        desc = "GitHub Issues",
      },
      localmap = map,
    })
    helper.setup("github-pulls", {
      sources = { {
        name = "github_repo_pull",
        params = { source = "cwd" },
      } },
    }, {
      start = {
        key = "<leader>fgp",
        desc = "GitHub Pull Requests",
      },
      localmap = map,
    })
    vim.api.nvim_create_user_command("DduSources", function()
      vim.fn["ddu#start"]({
        sources = { {
          name = "github_search_repo",
          params = { query = "topic:ddu-source" },
        } },
      })
    end, {})
    vim.api.nvim_create_user_command("DduFilters", function()
      vim.fn["ddu#start"]({
        sources = { {
          name = "github_search_repo",
          params = { query = "topic:ddu-filter" },
        } },
      })
    end, {})
    vim.api.nvim_create_user_command("DduKinds", function()
      vim.fn["ddu#start"]({
        sources = { {
          name = "github_search_repo",
          params = { query = "topic:ddu-kind" },
        } },
      })
    end, {})
  end,
}
return spec
