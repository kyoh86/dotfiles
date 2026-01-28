local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "shun/ddu-source-rg",
  config = function()
    helper.setup("search-dotfiles", {
      sources = { { name = "rg", options = {
        path = vim.env.XDG_CONFIG_HOME,
        matchers = {},
        volatile = true,
      } } },
    }, {
      start = {
        key = "<leader><leader>r",
        desc = "DotFiles検索",
      },
    })
    helper.setup("search-files", {
      sources = { { name = "rg", options = {
        matchers = {},
        volatile = true,
      } } },
    }, {
      start = {
        key = "<leader>fr",
        desc = "Files検索",
      },
    })
  end,
}

return spec
