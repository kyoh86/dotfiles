local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = { {
  "flow6852/ddu-source-qf",
  dependencies = { "Shougo/ddu.vim" },
  config = function()
    helper.start_by("<leader>fqc", "quickfix", { sources = { { name = "qf" } } })
    helper.map_for_file("quickfix")
  end,
}, {
  "kyoh86/ddu-source-quickfix_history",
  dependencies = { "Shougo/ddu.vim" },
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
} }
return spec
