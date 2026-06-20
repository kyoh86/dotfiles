local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddu-source-tmux",
  config = function()
    helper.setup("tmux-session", {
      sources = { { name = "tmux_session" } },
      kindOptions = {
        tmux_session = {
          defaultAction = "switch",
        },
      },
    }, {
      start = {
        key = "<leader>fts",
        desc = "セッション",
      },
      localmap = {
        ["<leader>a"] = { action = "itemAction", params = { name = "switch" } },
        ["<leader>d"] = { action = "itemAction", params = { name = "kill" } },
      },
    })
    helper.setup("tmux-pane", {
      sources = { { name = "tmux_pane" } },
      kindOptions = {
        tmux_pane = {
          defaultAction = "select",
        },
      },
    }, {
      start = {
        key = "<leader>ftp",
        desc = "ペイン",
      },
      localmap = {
        ["<leader>s"] = { action = "itemAction", params = { name = "select" } },
        ["<leader>d"] = { action = "itemAction", params = { name = "kill" } },
      },
    })
  end,
}
return spec
