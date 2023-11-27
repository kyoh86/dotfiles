local func = require("kyoh86.lib.func")
---@type LazySpec[]
local spec = {
  {
    "Shougo/ddu.vim",
    config = func.bind_all(vim.fn["ddu#custom#patch_global"], {
      sourceOptions = {
        _ = {
          ignoreCase = true,
        },
      },
    }),
    dependencies = { "denops.vim" },
  },
  { import = "kyoh86.plug.ddu.source" },
  { import = "kyoh86.plug.ddu.filter" },
  { import = "kyoh86.plug.ddu.kind" },
  { import = "kyoh86.plug.ddu.ui" },
}
return spec
