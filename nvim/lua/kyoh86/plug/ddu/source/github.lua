local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-github",
  dependencies = { "ddu.vim" },
  config = function()
    local custom_comment = function(tp, args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
        return 1
      end
      local url = args.items[1].action.html_url
      local words = vim.iter(vim.split(url, "/", { plain = true })):rev():totable()
      local number, _, name, owner, _ = unpack(words)
      require("kyoh86.conf.github.comment").create({ type = tp, repo = owner .. "/" .. name, number = number })
      return 0
    end

    local custom_view = function(args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
        return 1
      end
      local url = args.items[1].action.html_url
      local words = vim.iter(vim.split(url, "/", { plain = true })):rev():totable()
      local number, _, name, owner, _ = unpack(words)
      vim.cmd.drop("github://issue/view;owner=" .. owner .. "&repo=" .. name .. "&num=" .. number)
      return 0
    end

    vim.fn["ddu#custom#action"]("kind", "github_issue", "custom:issue-comment", function(args)
      return custom_comment("issue", args)
    end)

    vim.fn["ddu#custom#action"]("kind", "github_issue", "custom:view", function(args)
      return custom_view(args)
    end)

    vim.fn["ddu#custom#action"]("kind", "github_pull", "custom:pr-comment", function(args)
      return custom_comment("pr", args)
    end)

    vim.fn["ddu#custom#patch_global"]({
      kindOptions = {
        github_pull = {
          defaultAction = "browse",
        },
        github_issue = {
          defaultAction = "custom:view",
        },
        github_repo = {
          defaultAction = "browse",
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
        params = { source = "cwd", state = "all" },
        options = {
          matchers = { "matcher_github_issue_like", "matcher_fzf" },
        },
      } },
      uiParams = {
        ff = {
          inputFunc = "kyoh86#ddu#source#github#input#cancel",
        },
      },
      input = "is:open ",
    }, {
      start = {
        key = "<leader>fghi",
        desc = "GitHub Issues",
      },
      localmap = vim.tbl_extend("force", map, {
        ["<leader>c"] = { action = "itemAction", params = { name = "custom:issue-comment" } },
        ["<leader>t"] = function()
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
        params = { state = "all" },
        options = {
          columns = { "github_issue_full_name", "github_issue_title", "github_issue_state" },
          matchers = { "matcher_github_issue_like", "matcher_fzf" },
        },
      } },
      uiParams = {
        ff = {
          inputFunc = "kyoh86#ddu#source#github#input#cancel",
        },
      },
      input = "is:open ",
    }, {
      start = {
        key = "<leader>fghgi",
        desc = "GitHub My Issues",
      },
      localmap = vim.tbl_extend("force", map, {
        ["<leader>c"] = { action = "itemAction", params = { name = "custom:issue-comment" } },
        ["<leader>t"] = function()
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
        params = { source = "cwd", state = "all" },
        options = {
          matchers = { "matcher_github_issue_like", "matcher_fzf" },
        },
      } },
      uiParams = {
        ff = {
          inputFunc = "kyoh86#ddu#source#github#input#cancel",
        },
      },
      input = "is:open ",
    }, {
      start = {
        key = "<leader>fghp",
        desc = "GitHub Pull Requests",
      },
      localmap = vim.tbl_extend("force", map, {
        ["<leader>c"] = { action = "itemAction", params = { name = "custom:pr-comment" } },
        ["<leader>s"] = { action = "itemAction", params = { name = "checkout" } },
        ["<leader>t"] = function()
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
    helper.setup("github-my-pulls", {
      sources = { {
        name = "github_my_pull",
        params = { hostname = "github.com", role = "created", state = "all" },
        options = {
          matchers = { "matcher_github_issue_like", "matcher_fzf" },
        },
      } },
      uiParams = {
        ff = {
          inputFunc = "kyoh86#ddu#source#github#input#cancel",
        },
      },
      input = "is:open ",
    }, {
      start = {
        key = "<leader>fghgp",
        desc = "GitHub My Pull Requests",
      },
      localmap = vim.tbl_extend("force", map, {
        ["<leader>c"] = { action = "itemAction", params = { name = "custom:pr-comment" } },
        ["<leader>t"] = function()
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

    helper.setup("github-search-issues", {
      sources = { {
        name = "github_search_issue",
        params = { hostname = "github.com" },
      } },
      input = "is:open ",
    }, {
      localmap = vim.tbl_extend("force", map, {
        ["<leader>c"] = { action = "itemAction", params = { name = "custom:issue-comment" } },
      }),
    })

    helper.setup("github-search-pulls", {
      sources = { {
        name = "github_search_pull",
        params = { hostname = "github.com" },
      } },
      input = "is:open ",
    }, {
      localmap = vim.tbl_extend("force", map, {
        ["<leader>c"] = { action = "itemAction", params = { name = "custom:issue-comment" } },
      }),
    })

    -- Start all GitHub contexts
    local contextList = {
      { title = "Issues in current repo", context = "github-repo-issues" },
      { title = "Pull requests in current repo", context = "github-pulls" },
      { title = "My issues", context = "github-my-issues" },
      { title = "My pull requests", context = "github-my-pulls" },
    }
    local contextDict = vim.iter(contextList):fold({}, function(acc, item)
      acc[item.title] = item.context
      return acc
    end)
    local startContext = function(text)
      local context = contextDict[text]
      if not context or context == "" then
        return
      end

      vim.fn["ddu#start"]({
        name = context,
        push = true,
      })
    end
    local startContextId = vim.fn["denops#callback#register"](startContext, { once = false })
    helper.setup("github", {
      sources = { {
        name = "custom-list",
        params = {
          texts = vim
            .iter(contextList)
            :map(function(item)
              return item.title
            end)
            :totable(),
          callbackId = startContextId,
        },
      } },
      kindOptions = {
        ["custom-list"] = {
          defaultAction = "callback",
        },
      },
    }, {
      start = {
        key = "<leader>fgh",
        desc = "GitHub",
      },
    })

    vim.api.nvim_create_user_command("DduSources", function()
      vim.fn["ddu#start"]({
        sources = { {
          name = "github_search_repo",
          options = { input = "topic:ddu-source" },
        } },
      })
    end, {})
    vim.api.nvim_create_user_command("DduFilters", function()
      vim.fn["ddu#start"]({
        sources = { {
          name = "github_search_repo",
          options = { input = "topic:ddu-filter" },
        } },
      })
    end, {})
    vim.api.nvim_create_user_command("DduKinds", function()
      vim.fn["ddu#start"]({
        sources = { {
          name = "github_search_repo",
          options = { input = "topic:ddu-kind" },
        } },
      })
    end, {})
  end,
}
return spec
