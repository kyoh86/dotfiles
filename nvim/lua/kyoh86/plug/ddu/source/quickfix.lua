local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = { {
  "flow6852/ddu-source-qf",
  config = function()
    helper.start_by("<leader>fqc", "quickfix", { sources = { { name = "qf" } } })
    helper.map_for_file("quickfix")
  end,
  dependencies = { "Shougo/ddu.vim" },
}, {
  "kyoh86/ddu-source-quickfix_history",
  config = function()
    helper.start_by("<leader>fqh", "quickfix_history", { sources = { { name = "quickfix_history" } } })
    vim.fa.ddu.custom.patch_global({
      kindOptions = {
        quickfix_history = {
          defaultAction = "open",
        },
      },
    })
  end,
  dependencies = { "Shougo/ddu.vim" },
} }
return spec
