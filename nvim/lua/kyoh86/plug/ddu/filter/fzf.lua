-- local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "yuki-yano/ddu-filter-fzf",
  dependencies = { "ddu.vim" },
  config = function()
    vim.fn["ddu#custom#patch_global"]({
      sourceOptions = {
        _ = {
          matchers = { "matcher_fzf" },
          sorters = { "sorter_fzf" },
        },
      },
    })
  end,
}
return spec
