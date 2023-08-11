local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-git_branch",
  dependencies = { "ddu.vim" },
  config = function()
    kyoh86.ensure("momiji", function(m)
      vim.api.nvim_set_hl(0, "dduColumnGitBranchRemote", { fg = m.colors.blue })
      vim.api.nvim_set_hl(0, "dduColumnGitBranchLocal", { fg = m.colors.red })
      vim.api.nvim_set_hl(0, "dduColumnGitBranchAuthor", { fg = m.colors.green })
    end)
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
      } },
      kindOptions = {
        git_branch = { defaultAction = "switch" },
      },
    }, {
      startkey = "<leader>fgb",
      localmap = {
        ["<leader>d"] = { action = "itemAction", params = { name = "delete" } },
        ["<leader>r"] = { action = "itemAction", params = { name = "reset" } },
        ["<leader>c"] = { action = "itemAction", params = { name = "copy" } },
        ["<leader>l"] = { action = "itemAction", params = { name = "custom:logs" } },

        ["<leader>f"] = { action = "itemAction", params = { name = "fixupTo" } },
        ["<leader>y"] = { action = "itemAction", params = { name = "yank" } },
        ["<leader>p"] = { action = "itemAction", params = { name = "append" } },
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
      kyoh86.fa.ddu.start({
        name = args.options.name,
        push = true,
        sources = { { name = "git_log", params = { startingCommit = { branch } } } },
      })
      return 0
    end

    kyoh86.fa.ddu.custom.action("kind", "git_branch", "custom:logs", custom_logs)
  end,
}
return spec
