local helper = require("kyoh86.plug.ddu.helper")

local ui_name = "zenn-dev-article"

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-zenn_dev",
  dependencies = { { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "Milly/ddu-filter-kensaku", "Milly/ddu-filter-merge" } },
  config = function()
    helper.map_start("<leader>fza", {
      name = ui_name,
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
    })
    helper.map_ff_file(ui_name, {
      ["<leader>b"] = { action_name = "itemAction", params = { name = "browse" } },
    })
  end,
}
return spec
