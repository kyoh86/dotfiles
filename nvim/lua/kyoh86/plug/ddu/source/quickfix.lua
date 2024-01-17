local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = { {
  "flow6852/ddu-source-qf",
  dependencies = { "ddu.vim" },
  config = helper.setup_func("quickfix", { sources = { { name = "qf" } } }, {
    start = {
      key = "<leader>fqc",
      desc = "Quickfix",
    },
    filelike = true,
  }),
}, {
  "kyoh86/ddu-source-quickfix_history",
  dependencies = { "ddu.vim" },
  config = helper.setup_func("quickfix-history", {
    sources = { { name = "quickfix_history" } },
    kindOptions = {
      quickfix_history = {
        defaultAction = "open",
      },
    },
  }, {
    start = {
      key = "<leader>fqh",
      desc = "Quickfix履歴",
    },
  }),
} }
return spec
