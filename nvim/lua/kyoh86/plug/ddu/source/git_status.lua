local helper = require("kyoh86.plug.ddu.helper")

local deletedTree = vim.regex("D $")
local function isDeleted(status)
  return status == "D  " or (deletedTree:match_str(status) ~= nil)
end

local function custom_open(editor)
  return function(args)
    for _, item in ipairs(args.items) do
      if item.action == nil then
      -- noop
      else
        local action = item.action
        if isDeleted(action.status) then
          -- noop
        else
          vim.cmd(string.format("%s %s", editor, action.path))
        end
      end
    end
    return 0
  end
end

---@type LazySpec
local spec = {
  "kuuote/ddu-source-git_status",
  dependencies = { "ddu.vim" },
  config = function()
    require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
      kyoh86.ensure(colors_name, function(m)
        vim.api.nvim_set_hl(0, "dduGitStatusAdded", { fg = m.colors.green })
        vim.api.nvim_set_hl(0, "dduGitStatusModified", { fg = m.colors.yellow })
        vim.api.nvim_set_hl(0, "dduGitStatusDeleted", { fg = m.colors.red, bold = true })
        vim.api.nvim_set_hl(0, "dduGitStatusUntracked", { fg = m.colors.blue })
      end)
    end, true)
    vim.fn["ddu#custom#action"]("kind", "git_status", "custom:edit", custom_open("edit"))
    vim.fn["ddu#custom#action"]("kind", "git_status", "custom:vnew", custom_open("vnew"))
    vim.fn["ddu#custom#action"]("kind", "git_status", "custom:new", custom_open("new"))
    helper.setup("git-status", {
      sources = { {
        name = "git_status",
        options = {
          converters = {
            { name = "converter_hl_dir" },
            { name = "converter_git_status_custom" },
          },
        },
      } },
      filterParams = {
        converter_git_status_custom = {
          highlightAdded = "dduGitStatusAdded",
          highlightModified = "dduGitStatusModified",
          highlightDeleted = "dduGitStatusDeleted",
          highlightUntracked = "dduGitStatusUntracked",
        },
      },
      kindOptions = {
        git_status = {
          defaultAction = "custom:edit",
        },
      },
    }, {
      start = {
        key = "<leader>fgs",
        desc = "Git Status",
      },
      localmap = {
        ["<leader>a"] = { action = "itemAction", params = { name = "add" } },
        ["<leader>r"] = { action = "itemAction", params = { name = "reset" } },
        ["<leader>x"] = { action = "itemAction", params = { name = "custom:new" } },
        ["<leader>v"] = { action = "itemAction", params = { name = "custom:vnew" } },
      },
    })
  end,
}
return spec
