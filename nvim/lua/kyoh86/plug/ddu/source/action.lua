local func = require("kyoh86.lib.func")

---@type LazySpec
local spec = {
  "Shougo/ddu-source-action",
  dependencies = { "ddu.vim" },
  config = func.bind_all(vim.fn["ddu#custom#patch_global"], {
    kindParams = { action = { quit = true } },
    kindOptions = { action = { defaultAction = "do" } },
  }),
}
return spec
