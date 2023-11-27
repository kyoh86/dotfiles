local func = require("kyoh86.lib.func")
---@type LazySpec
local spec = {
  "kuuote/ddu-filter-fuse",
  config = func.bind_all(vim.fn["ddu#custom#patch_global"], {
    filterParams = {
      matcher_fuse = {
        threshold = 0.6,
      },
    },
  }),
  dependencies = { "ddu.vim" },
}
return spec
