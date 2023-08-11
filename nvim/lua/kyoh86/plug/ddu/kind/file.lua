-- local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "Shougo/ddu-kind-file",
  dependencies = { "ddu.vim" },
  config = function()
    vim.fn["ddu#custom#patch_global"]({
      kindOptions = {
        file = {
          defaultAction = "open",
        },
      },
    })
  end,
}
return spec
