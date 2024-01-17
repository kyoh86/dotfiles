local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "4513ECHO/ddu-source-emoji",
  dependencies = { "ddu.vim", "ddu-kind-word" },
  config = function()
    helper.setup("emoji-emoji", {
      sources = { { name = "emoji", options = { defaultAction = "append" } } },
    }, {
      start = {
        key = "<leader>fee",
        desc = "絵文字",
      },
    })
    helper.setup("emoji-slug", {
      sources = { { name = "emoji", options = { defaultAction = "append" }, params = { convertEmoji = false } } },
    }, {
      start = {
        key = "<leader>fes",
        desc = "絵文字slug",
      },
    })
  end,
}
return spec
