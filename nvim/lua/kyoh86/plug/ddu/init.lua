---@type LazySpec[]
local spec = {
  {
    "Shougo/ddu.vim",
    config = function()
      kyoh86.fa.ddu.custom.patch_global({
        sourceOptions = {
          _ = {
            ignoreCase = true,
          },
        },
      })
    end,
    dependencies = { "denops.vim" },
  },
  { import = "kyoh86.plug.ddu.source" },
  { import = "kyoh86.plug.ddu.filter" },
  { import = "kyoh86.plug.ddu.kind" },
  { import = "kyoh86.plug.ddu.ui" },
}
return spec
