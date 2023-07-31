local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-zenn_dev",
  dependencies = { { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "Milly/ddu-filter-kensaku", "Milly/ddu-filter-merge" } },
  config = function()
    helper.setup("zenn-dev-article", {
      sources = { {
        name = "zenn_dev_article",
      } },
      sourceOptions = {
        _ = {
          matchers = { "merge" },
          columns = { "zenn_dev_slug", "zenn_dev_emoji", "zenn_dev_title" },
        },
      },
      filterParams = {
        merge = {
          filters = {
            { name = "matcher_kensaku", weight = 1 },
            { name = "matcher_fzf", weight = 1 },
          },
          unique = true,
        },
      },
    }, {
      startkey = "<leader>fza",
      filelike = true,
      localmap = {
        ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
      },
    })
  end,
}
return spec
