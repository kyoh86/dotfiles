local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "4513ECHO/ddu-source-emoji",
  dependencies = { "ddu.vim", "ddu-kind-word" },
  config = function()
    helper.setup("emoji-emoji", {
      sources = { { name = "emoji", options = { defaultAction = "append" } } },
    }, {
      startkey = "<leader>fee",
    })
    helper.setup("emoji-slug", {
      sources = { { name = "emoji", options = { defaultAction = "append" }, params = { convertEmoji = false } } },
    }, {
      startkey = "<leader>fes",
    })
  end,
}
return spec
