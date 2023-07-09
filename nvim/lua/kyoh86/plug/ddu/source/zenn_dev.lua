local helper = require("kyoh86.plug.ddu.helper")

---@return DduOptions
local function option()
  ---@type DduOptions
  local o = {
    sources = { {
      name = "zenn_dev_article",
      params = { cwd = vim.fn.getcwd() },
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
  }
  return o
end

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-zenn_dev",
  dev = true,
  dependencies = { { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "Milly/ddu-filter-kensaku", "Milly/ddu-filter-merge" } },
  config = function()
    helper.map_start("<leader>fza", "zenn-dev-article", option)
    helper.map_ff_file("zenn-dev-article", function(map)
      map("<leader>b", helper.action("itemAction", { name = "browse" }))
    end)
  end,
}
return spec
