-- local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-filter-converter_hl_dir",
  dependencies = { "ddu.vim" },
  config = function()
    kyoh86.ensure("momiji", function(m)
      vim.api.nvim_set_hl(0, "dduDir1", { fg = m.colors.green })
      vim.api.nvim_set_hl(0, "dduDir2", { fg = m.colors.lightgreen })
      vim.fn["ddu#custom#patch_global"]({
        filterParams = {
          converter_hl_dir = {
            hlGroup = { "dduDir1", "dduDir2" },
          },
        },
      })
    end)
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
