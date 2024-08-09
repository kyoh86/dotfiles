local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-gogh",
  dependencies = { "ddu.vim", "ddu-kind-file" },
  config = function()
    local custom_ff_file = function(args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
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

    helper.setup("gogh-project", {
      sources = { { name = "gogh_project" } },
      kindOptions = {
        gogh_project = {
          defaultAction = "cd",
        },
      },
      actionParams = {
        browse = { opener = require("kyoh86.glaze.stain.opener") },
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
        ["<leader>f"] = { action = "itemAction", params = { name = "custom:ff_file" } },
      },
    })

    helper.setup("gogh-repo", {
      sources = { { name = "gogh_repo", params = { limit = -1 } } },
      kindOptions = {
        gogh_repo = {
          defaultAction = "browse",
        },
      },
      actionParams = {
        browse = { opener = require("kyoh86.glaze.stain.opener") },
      },
    }, {
      start = {
        key = "<leader>fpr",
        desc = "リポジトリ",
      },
      localmap = {
        ["<leader>g"] = { action = "itemAction", params = { name = "get" } },
      },
    })
  end,
}
return spec
