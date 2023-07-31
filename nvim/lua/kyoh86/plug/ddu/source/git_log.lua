local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-git_log",
  dependencies = { "Shougo/ddu.vim", "kyoh86/ddu-source-git_diff_tree" },
  config = function()
    ---@param args DduActionArguments
    local custom_files = function(args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
        return 1
      end
      kyoh86.fa.ddu.start({
        name = args.options.name,
        push = true,
        sources = { { name = "git_diff_tree", params = { commitHash = args.items[1].action.hash } } },
      })
      return 0
    end
    kyoh86.fa.ddu.custom.action("kind", "git_commit", "custom:files", custom_files)

    local name = "git-log"
    helper.map_start("<leader>fgl", {
      name = name,
      sources = { { name = "git_log" } },
      kindOptions = {
        git_commit = { defaultAction = "custom:files" },
      },
    })

    helper.map_ff_file(name, {
      ["<leader>f"] = { action_name = "itemAction", params = { name = "fixupTo" } },
      ["<leader>y"] = { action_name = "itemAction", params = { name = "yank" } },
      ["<leader>p"] = { action_name = "itemAction", params = { name = "append" } },
      ["<leader>r"] = { action_name = "itemAction", params = { name = "reset" } },
    })
  end,
}
return spec
