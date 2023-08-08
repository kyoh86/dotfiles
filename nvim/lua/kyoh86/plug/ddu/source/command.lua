local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-command",
  dependencies = { "ddu.vim", "ddu-kind-word" },
  config = function()
    helper.setup("command", {
      sources = { { name = "command" } },
      kindOptions = {
        command = {
          defaultAction = "edit",
        },
      },
    }, {
      startkey = "<leader>f:",
    })
  end,
}
return spec
