local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "matsui54/ddu-source-command_history",
  dependencies = { "ddu.vim" },
  config = helper.setup_func("command-history", {
    sources = { { name = "command_history" } },
    kindOptions = {
      command_history = {
        defaultAction = "execute",
      },
    },
  }, {
    startkey = "<leader>f;",
    localmap = {
      ["<leader>e"] = { action = "itemAction", params = { name = "edit" } },
    },
  }),
}
return spec
