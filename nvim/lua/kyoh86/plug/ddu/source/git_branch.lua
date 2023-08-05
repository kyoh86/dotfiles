local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-git_branch",
  dependencies = { "Shougo/ddu.vim" },
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
      },
    })
  end,
}
return spec
