local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-filter-converter_hl_dir",
  dev = true,
  config = function()
    vim.fa.ddu.custom.patch_global({
      sourceOptions = {
        _ = {
          converters = { { name = "converter_hl_dir" } },
        },
      },
    })
  end,
  dependencies = { { "Shougo/ddu.vim" } },
}
return spec
