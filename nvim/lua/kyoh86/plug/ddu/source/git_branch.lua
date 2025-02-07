local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-git_branch",
  dependencies = { "ddu.vim" },
  config = function()
    require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
      kyoh86.ensure(colors_name, function(m)
        vim.api.nvim_set_hl(0, "dduColumnGitBranchRemote", { fg = m.colors.blue })
        vim.api.nvim_set_hl(0, "dduColumnGitBranchLocal", { fg = m.colors.red })
        vim.api.nvim_set_hl(0, "dduColumnGitBranchAuthor", { fg = m.colors.green })
      end)
    end, true)
    helper.setup("git-branch", {
      sources = { {
        name = "git_branch",
        options = {
          columns = {
            "git_branch_head",
            "git_branch_remote",
            "git_branch_name",
            "git_branch_upstream",
            "git_branch_author",
            "git_branch_date",
          },
        },
        params = {
          remote = true,
        },
      } },
      kindOptions = {
        git_branch = { defaultAction = "switch" },
      },
    }, {
      start = {
        key = "<leader>fgb",
        desc = "Git Branch",
      },
      localmap = {
        ["<leader>d"] = { action = "itemAction", params = { name = "delete" } },
        ["<leader>c"] = { action = "itemAction", params = { name = "createFrom" } },
        ["<leader>l"] = { action = "itemAction", params = { name = "custom:logs" } },

        ["<leader>R"] = { action = "itemAction", params = { name = "rebaseTo" } },
        ["<leader>y"] = { action = "itemAction", params = { name = "yankName" } },
      },
    })

    local custom_logs = function(args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
        return 1
      end
      local refName = args.items[1].action.refName
      local branch = refName.branch
      if refName.remote ~= "" then
        branch = refName.remote .. "/" .. branch
      end
      vim.fn["ddu#start"]({
        name = "git-log",
        push = true,
        sources = { { name = "git_log", params = { startingCommit = { branch } } } },
      })
      return 0
    end

    vim.fn["ddu#custom#action"]("kind", "git_branch", "custom:logs", custom_logs)
  end,
}
return spec
