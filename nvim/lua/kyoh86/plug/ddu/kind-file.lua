-- local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "Shougo/ddu-kind-file",
  config = function()
    vim.fa.ddu.custom.patch_global({
      kindOptions = {
        file = {
          defaultAction = "open",
        },
      },
    })
  end,
  dependencies = { { "Shougo/ddu.vim" } },
}
return spec
