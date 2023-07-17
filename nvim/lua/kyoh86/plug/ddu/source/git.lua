local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  {
    "tennashi/ddu-source-git",
    dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "kyoh86/ddu-source-git_diff_tree" },
    config = function()
      do
        local source = "git_status"
        local name = "git-status"
        helper.map_start("<leader>fgs", name, {
          sources = { { name = source } },
          sourceOptions = {
            _ = {
              converters = { "git_status_highlight" },
            },
          },
          kindOptions = {
            git_working_tree = {
              defaultAction = "custom:edit",
            },
            git_index = {
              defaultAction = "custom:edit",
            },
          },
        })

        local opener = function(command)
          ---@param args DduActionArguments
          return function(args)
            if #args.items ~= 1 then
              vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
              return 1
            end

            local status = args.items[1].action.fileStatus
            if status.workingTreeState == "deleted" then
              vim.notify("invalid action: deleted file may not be editable", vim.log.levels.WARN, {})
              return 0
            end
            vim.cmd[command](status.path)
            return 0
          end
        end
        kyoh86.fa.ddu.custom.action("kind", "git_working_tree", "custom:edit", opener("edit"))
        kyoh86.fa.ddu.custom.action("kind", "git_working_tree", "custom:vnew", opener("vnew"))
        kyoh86.fa.ddu.custom.action("kind", "git_working_tree", "custom:new", opener("new"))
        kyoh86.fa.ddu.custom.action("kind", "git_index", "custom:edit", opener("edit"))
        kyoh86.fa.ddu.custom.action("kind", "git_index", "custom:vnew", opener("vnew"))
        kyoh86.fa.ddu.custom.action("kind", "git_index", "custom:new", opener("new"))
        helper.map_ff(name, {
          ["<leader>x"] = { action_name = "itemAction", params = { name = "custom:new" } },
          ["<leader>v"] = { action_name = "itemAction", params = { name = "custom:vnew" } },
          ["<leader>a"] = { action_name = "itemAction", params = { name = "add" } },
          ["<leader>r"] = { action_name = "itemAction", params = { name = "restore" } },
        })
      end

      do
        local source = "git_ref"
        local name = "git-ref"
        helper.map_start("<leader>fgr", name, {
          sources = { { name = source } },
          kindOptions = {
            git_branch = { defaultAction = "switch" },
            git_tag = { defaultAction = "switch" },
          },
        })
        helper.map_ff(name, {
          ["<leader>d"] = { action_name = "itemAction", params = { name = "delete" } },
        })
      end

      do
        ---@param args DduActionArguments
        local custom_files = function(args)
          if #args.items ~= 1 then
            vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
            return 1
          end
          kyoh86.fa.ddu.start({
            name = args.options.name,
            push = true,
            sources = { { name = "git_diff_tree", params = { commitHash = args.items[1].action.commitHash } } },
          })
          return 0
        end
        kyoh86.fa.ddu.custom.action("kind", "git_commit", "custom:files", custom_files)

        local source = "git_log"
        local name = "git-log"
        helper.map_start("<leader>fgl", name, {
          sources = { { name = source } },
          kindOptions = {
            git_commit = { defaultAction = "custom:files" },
          },
        })

        helper.map_ff_file(name, {
          ["<leader>f"] = { action_name = "itemAction", params = { name = "fixupTo" } },
        })
      end
    end,
  },
  {
    "kyoh86/ddu-source-git_diff_tree",
  },
}
return spec
