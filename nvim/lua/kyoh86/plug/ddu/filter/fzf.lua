local func = require("kyoh86.lib.func")

---@type LazySpec
local spec = {
  "yuki-yano/ddu-filter-fzf",
  dependencies = { "ddu.vim" },
  config = func.bind_all(vim.fn["ddu#custom#patch_global"], {
    sourceOptions = {
      _ = {
        matchers = { "matcher_fzf" },
        sorters = { "sorter_fzf" },
      },
    },
  }),
}
return spec
