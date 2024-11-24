-- local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-filter-converter_hl_dir",
  dependencies = { "ddu.vim" },
  config = function()
    require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
      kyoh86.ensure(colors_name, function(m)
        vim.api.nvim_set_hl(0, "dduDir1", { fg = m.colors.red })
        vim.api.nvim_set_hl(0, "dduDir2", { fg = m.colors.yellow })
      end)
    end, true)
    vim.fn["ddu#custom#patch_global"]({
      filterParams = {
        converter_hl_dir = {
          hlGroup = { "dduDir1", "dduDir2" },
        },
      },
    })
    vim.fn["ddu#custom#patch_global"]({
      sourceOptions = {
        _ = {
          converters = { { name = "converter_hl_dir" } },
        },
      },
    })
  end,
}
return spec
