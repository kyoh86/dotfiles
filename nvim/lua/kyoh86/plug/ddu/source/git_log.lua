local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-git_log",
  dependencies = { "ddu.vim" },
  config = function()
    local custom_files = function(args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
        return 1
      end
      vim.fn["ddu#start"]({
        name = args.options.name,
        push = true,
        sources = { { name = "git_diff_tree", params = { commitHash = args.items[1].action.hash } } },
      })
      return 0
    end
    vim.fn["ddu#custom#action"]("kind", "git_commit", "custom:files", custom_files)

    helper.setup("git-log", {
      sources = { { name = "git_log" } },
      kindOptions = {
        git_commit = { defaultAction = "custom:files" },
      },
    }, {
      start = {
        key = "<leader>fgl",
        desc = "Git Log",
      },
      filelike = true,
      localmap = {
        ["<leader>f"] = { action = "itemAction", params = { name = "fixupTo" } },
        ["<leader>y"] = { action = "itemAction", params = { name = "yank" } },
        ["<leader>p"] = { action = "itemAction", params = { name = "append" } },
        ["<leader>r"] = { action = "itemAction", params = { name = "reset" } },
      },
    })
  end,
}
return spec
