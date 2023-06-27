local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-zenn_dev",
  dev = true,
  dependencies = { { "Shougo/ddu.vim", "Shougo/ddu-kind-file" } },
  config = function()
    helper.map_start("<leader>fza", "zenn-dev-article", function()
      return {
        sources = { {
          name = "zenn_dev_article",
          params = {
            cwd = vim.fn.getcwd(),
          },
        } },
      }
    end)
  end,
}
return spec
