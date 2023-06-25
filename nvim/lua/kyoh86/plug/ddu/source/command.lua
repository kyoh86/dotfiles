local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-command",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-word" },
  config = function()
    local name = "command"
    local source = "command"
    helper.start_by("<leader>f:", name, {
      sources = { { name = source } },
      kindOptions = {
        [source] = {
          defaultAction = "edit",
        },
      },
    })
  end,
}
return spec
