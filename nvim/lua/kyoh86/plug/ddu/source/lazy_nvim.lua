local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-lazy_nvim",
  dependencies = { "ddu.vim", "ddu-kind-file", "lazy.nvim" },
  config = function()
    local custom_ff_file = function(args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can edit only one file at once", vim.log.levels.WARN, {})
        return 1
      end
      local path = args.items[1].action.path
      vim.fn["ddu#start"]({
        name = "file-all",
        push = true,
        sources = { { name = "file_rec", options = { path = path } } },
      })
      return 0
    end
    vim.fn["ddu#custom#action"]("kind", "file", "custom:ff_file", custom_ff_file)
    helper.setup("lazy_nvim", {
      sources = { { name = "lazy_nvim" } },
      kindOptions = {
        file = {
          defaultAction = "cd",
        },
      },
    }, {
      start = {
        key = "<leader><leader>p",
        desc = "lazy.nvim プラグイン",
      },
      filelike = true,
      localmap = {
        ["<leader>e"] = { action = "itemAction", params = { name = "open" } },
        ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
        ["<leader>g"] = { action = "itemAction", params = { name = "grep_config" } },
        ["<leader>c"] = { action = "itemAction", params = { name = "grep_config" } },
        ["<leader>f"] = { action = "itemAction", params = { name = "custom:ff_file" } },
      },
    })
  end,
}
return spec
