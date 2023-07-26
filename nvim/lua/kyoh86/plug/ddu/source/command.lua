local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-command",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-word" },
  config = function()
    helper.map_start("<leader>f:", {
      name = "command",
      sources = { { name = "command" } },
      kindOptions = {
        command = {
          defaultAction = "edit",
        },
      },
    })
  end,
}
return spec
