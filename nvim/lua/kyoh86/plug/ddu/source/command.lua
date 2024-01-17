local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-command",
  dependencies = { "ddu.vim", "ddu-kind-word" },
  config = helper.setup_func("command", {
    sources = { { name = "command" } },
    kindOptions = {
      command = {
        defaultAction = "edit",
      },
    },
  }, {
    start = {
      key = "<leader>f:",
      desc = "コマンド",
    },
  }),
}
return spec
