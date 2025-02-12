local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  {
    "kyoh86/ddu-source-zenn_dev",
    dependencies = { "ddu.vim", "ddu-kind-file", "ddu-filter-kensaku", "ddu-filter-sorter_alpha" },
    config = function()
      helper.setup("zenn-dev-article", {
        sources = { {
          name = "zenn_dev_article",
        } },
        uiParams = {
          ff = {
            reversed = true,
          },
        },
        sourceOptions = {
          _ = {
            matchers = { "merge" },
            columns = { "zenn_dev_date", "zenn_dev_emoji", "zenn_dev_title" },
            sorters = { "sorter_alpha", "sorter_fzf" },
          },
        },
        kindOptions = {
          zenn_dev_article = {
            defaultAction = "open",
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
        start = {
          key = "<leader>fza",
          desc = "Zenn.dev記事",
        },
        filelike = true,
        localmap = {
          ["<leader>b"] = { action = "itemAction", params = { name = "browse" } },
        },
      })
    end,
  },
}
return spec
