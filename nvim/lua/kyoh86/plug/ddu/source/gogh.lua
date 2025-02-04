local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-gogh",
  dependencies = { "ddu.vim", "ddu-kind-file" },
  config = function()
    local custom_ff_file = function(args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can open ff only one project at once", vim.log.levels.WARN, {})
        return 1
      end
      local path = args.items[1].action.path
      vim.fn["ddu#start"]({
        name = args.options.name,
        push = true,
        sources = { { name = "file_rec", options = { path = path } } },
      })
      return 0
    end
    vim.fn["ddu#custom#action"]("kind", "gogh_project", "custom:ff_file", custom_ff_file)

    local custom_gh_issue = function(args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can open only one issues at once", vim.log.levels.WARN, {})
        return 1
      end
      local action = args.items[1].action
      vim.fn["ddu#start"]({
        name = "github-repo-issues",
        push = true,
        sources = { {
          name = "github_repo_issue",
          params = { source = "repo", owner = action.owner or action.spec.owner, name = action.name or action.spec.name },
          options = {
            matchers = { "matcher_github_issue_like", "matcher_fzf" },
          },
        } },
      })
      return 0
    end
    vim.fn["ddu#custom#action"]("kind", "gogh_project", "custom:gh_issue", custom_gh_issue)
    vim.fn["ddu#custom#action"]("kind", "gogh_repo", "custom:gh_issue", custom_gh_issue)

    helper.setup("gogh-project", {
      sources = { { name = "gogh_project" } },
      kindOptions = {
        gogh_project = {
          defaultAction = "cd",
        },
      },
    }, {
      start = {
        key = "<leader>fpl",
        desc = "プロジェクト",
      },
      filelike = true,
      localmap = {
        ["<leader>e"] = { action = "itemAction", params = { name = "open" } },
        ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
        ["<leader>ff"] = { action = "itemAction", params = { name = "custom:ff_file" } },
        ["<leader>fi"] = { action = "itemAction", params = { name = "custom:gh_issue" } },
      },
    })

    helper.setup("gogh-repo", {
      sources = { { name = "gogh_repo", params = { limit = -1 } } },
      kindOptions = {
        gogh_repo = {
          defaultAction = "browse",
        },
      },
    }, {
      start = {
        key = "<leader>fpr",
        desc = "リポジトリ",
      },
      localmap = {
        ["<leader>g"] = { action = "itemAction", params = { name = "get" } },
        ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
        ["<leader>fi"] = { action = "itemAction", params = { name = "custom:gh_issue" } },
      },
    })
  end,
}
return spec
