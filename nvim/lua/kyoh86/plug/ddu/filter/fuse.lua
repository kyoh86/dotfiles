-- local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kuuote/ddu-filter-fuse",
  config = function()
    vim.fa.ddu.custom.patch_global({
      filterParams = {
        matcher_fuse = {
          threshold = 0.6,
        },
      },
    })
  end,
  dependencies = { { "Shougo/ddu.vim" } },
}
return spec
