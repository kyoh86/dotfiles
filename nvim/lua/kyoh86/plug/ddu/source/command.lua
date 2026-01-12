local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec[]
local spec = {
  {
    "kyoh86/ddu-kind-command",
  },
  {
    "kyoh86/ddu-source-command",
    dependencies = { "ddu.vim", "ddu-kind-word", "ddu-kind-command" },
    config = helper.setup_func("command", {
      sources = { { name = "command" } },
      kindOptions = {
        command = {
          defaultAction = "edit",
        },
      },
      uiParams = {
        ff = {
          startAutoAction = true,
        },
      },
    }, {
      start = {
        key = "<leader>f:",
        desc = "コマンド",
      },
    }),
  },
  {
    "kyoh86/ddu-source-command_history",
    dependencies = { "ddu.vim", "ddu-kind-word", "ddu-kind-command" },
    config = helper.setup_func("command-history", {
      sources = { { name = "command_history", params = { parse = true } } },
      kindOptions = {
        command = {
          defaultAction = "edit",
        },
      },
      uiParams = {
        ff = {
          startAutoAction = true,
        },
      },
    }, {
      start = { key = "<leader>f;", desc = "コマンド履歴" },
      localmap = {
        ["<leader>e"] = { action = "itemAction", params = { name = "edit" } },
      },
    }),
  },
}
return spec
