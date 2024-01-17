local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "flow6852/ddu-source-vim_function",
  dependencies = { "ddu.vim", "denops.vim", "flow6852/ddu-kind-vim_type" },
  config = helper.setup_func("vim-function", {
    sources = { { name = "vim_function" } },
    kindOptions = {
      vim_type = {
        defaultAction = "insert",
      },
    },
  }, {
    start = {
      key = "<leader>fvf",
      desc = "Vim関数",
    },
  }),
}
return spec
