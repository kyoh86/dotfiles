local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = { {
  "flow6852/ddu-source-qf",
  dependencies = { "Shougo/ddu.vim" },
  config = function()
    local name = "quickfix"
    helper.map_start("<leader>fqc", { name = name, sources = { { name = "qf" } } })
    helper.map_ff_file(name)
  end,
}, {
  "kyoh86/ddu-source-quickfix_history",
  dependencies = { "Shougo/ddu.vim" },
  config = function()
    helper.map_start("<leader>fqh", { name = "quickfix-history", sources = { { name = "quickfix_history" } } })
    kyoh86.fa.ddu.custom.patch_global({
      kindOptions = {
        quickfix_history = {
          defaultAction = "open",
        },
      },
    })
  end,
} }
return spec
