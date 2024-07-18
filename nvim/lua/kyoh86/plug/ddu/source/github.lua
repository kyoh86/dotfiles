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

    local linkFormat = "${this.html_url.replace(/^https:\\/\\/[^\\/]+\\/([^\\/]+)\\/([^\\/]+)\\/(?:issues|pull)\\/(\\d+)/, '$1/$2#$3')}"
    local fullFormat = "${this.title} ${this.html_url.replace(/^https:\\/\\/[^\\/]+\\/([^\\/]+)\\/([^\\/]+)\\/(?:issues|pull)\\/(\\d+)/, '$1/$2#$3')}"
    local map = {
      ["<leader>e"] = { action = "itemAction", params = { name = "edit" } },
      ["<leader>p"] = { action = "itemAction", params = { name = "append", params = { format = linkFormat, avoid = "filename" } } },
      ["<leader>P"] = { action = "itemAction", params = { name = "insert", params = { format = linkFormat, avoid = "filename" } } },
      ["<leader>f"] = { action = "itemAction", params = { name = "append", params = { format = fullFormat } } },
      ["<leader>F"] = { action = "itemAction", params = { name = "insert", params = { format = fullFormat } } },
    }
    local nextState = {
      open = "closed",
      closed = "all",
      all = "open",
    }
    helper.setup("github-repo-issues", {
      sources = { {
        name = "github_repo_issue",
        params = { source = "cwd" },
      } },
    }, {
      start = {
        key = "<leader>fgi",
        desc = "GitHub Issues",
      },
      localmap = vim.tbl_extend("force", map, {
        ["<leader>s"] = function()
          local opts = vim.fn["ddu#custom#get_current"]("github-repo-issues")
          local state = nextState[opts.sourceParams.github_repo_issue.state]
          vim.fn["ddu#ui#do_action"]("updateOptions", {
            sourceParams = {
              github_repo_issue = {
                state = state,
              },
            },
          })
          vim.fn["ddu#ui#do_action"]("redraw", { method = "refreshItems" })
        end,
      }),
    })
    helper.setup("github-my-issues", {
      sources = { {
        name = "github_my_issue",
        options = {
          columns = { "github_issue_full_name", "github_issue_title", "github_issue_state" },
        },
      } },
    }, {
      start = {
        key = "<leader>fggi",
        desc = "GitHub My Issues",
      },
      localmap = vim.tbl_extend("force", map, {
        ["<leader>s"] = function()
          local opts = vim.fn["ddu#custom#get_current"]("github-my-issues")
          local state = nextState[opts.sourceParams.github_my_issue.state]
          vim.fn["ddu#ui#do_action"]("updateOptions", {
            sourceParams = {
              github_my_issue = {
                state = state,
              },
            },
          })
          vim.fn["ddu#ui#do_action"]("redraw", { method = "refreshItems" })
        end,
      }),
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
      localmap = vim.tbl_extend("force", map, {
        ["<leader>c"] = { action = "itemAction", params = { name = "checkout" } },
        ["<leader>s"] = function()
          local opts = vim.fn["ddu#custom#get_current"]("github-pulls")
          local state = nextState[opts.sourceParams.github_repo_pull.state]
          vim.fn["ddu#ui#do_action"]("updateOptions", {
            sourceParams = {
              github_repo_pull = {
                state = state,
              },
            },
          })
          vim.fn["ddu#ui#do_action"]("redraw", { method = "refreshItems" })
        end,
      }),
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
