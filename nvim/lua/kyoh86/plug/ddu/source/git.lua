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
        helper.start_by("<leader>fgs", name, {
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
          },
        })

        local opener = function(command)
          ---@param args DduActionArguments
          return function(args)
            if #args.items ~= 1 then
              vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
              return 1
            end
            vim.cmd[command](args.items[1].action.fileStatus.path)
            return 0
          end
        end
        vim.fa.ddu.custom.action("kind", "git_working_tree", "custom:edit", opener("edit"))
        vim.fa.ddu.custom.action("kind", "git_working_tree", "custom:vnew", opener("vnew"))
        vim.fa.ddu.custom.action("kind", "git_working_tree", "custom:new", opener("new"))
        helper.ff_map(name, function(map)
          map("<leader>x", helper.action("itemAction", { name = "custom:new" }))
          map("<leader>v", helper.action("itemAction", { name = "custom:vnew" }))
          map("<leader>a", helper.action("itemAction", { name = "add" }))
          map("<leader>r", helper.action("itemAction", { name = "restore" }))
        end)
      end

      do
        local source = "git_ref"
        local name = "git-ref"
        helper.start_by("<leader>fgr", name, {
          sources = { { name = source } },
          kindOptions = {
            git_branch = { defaultAction = "switch" },
            git_tag = { defaultAction = "switch" },
          },
        })
        helper.ff_map(name, function(map)
          map("<leader>d", helper.action("itemAction", { name = "delete" }))
        end)
      end

      do
        ---@param args DduActionArguments
        local custom_files = function(args)
          if #args.items ~= 1 then
            vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
            return 1
          end
          vim.fa.ddu.start({
            name = args.options.name,
            push = true,
            sources = { { name = "git_diff_tree", params = { commitHash = args.items[1].action.commitHash } } },
          })
          return 0
        end
        vim.fa.ddu.custom.action("kind", "git_commit", "custom:files", custom_files)

        local source = "git_log"
        local name = "git-log"
        helper.start_by("<leader>fgl", name, {
          sources = { { name = source } },
          kindOptions = {
            git_commit = { defaultAction = "custom:files" },
          },
        })

        helper.map_for_file(name, function(map)
          map("<leader>f", helper.action("itemAction", { name = "fixupTo" }))
        end)
      end
    end,
  },
  {
    "kyoh86/ddu-source-git_diff_tree",
  },
}
return spec
