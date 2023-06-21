-- local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "yuki-yano/ddu-filter-fzf",
  config = function()
    vim.fa.ddu.custom.patch_global({
      sourceOptions = {
        _ = {
          matchers = { "matcher_fzf" },
          sorters = { "sorter_fzf" },
        },
      },
    })
  end,
  dependencies = { { "Shougo/ddu.vim" } },
}
return spec
