local func = require("kyoh86.lib.func")
-- local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "Shougo/ddu-kind-file",
  dependencies = { "ddu.vim" },
  config = func.bind_all(vim.fn["ddu#custom#patch_global"], {
    kindOptions = {
      file = {
        defaultAction = "open",
      },
    },
  }),
}
return spec
