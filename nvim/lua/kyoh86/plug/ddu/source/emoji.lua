local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "4513ECHO/ddu-source-emoji",
  config = function()
    helper.start_by("<leader>fee", "emoji", {
      sources = { { name = "emoji", options = { defaultAction = "append" } } },
    })
    helper.start_by("<leader>fes", "emoji-slug", {
      sources = { { name = "emoji", options = { defaultAction = "append" }, params = { convertEmoji = false } } },
    })
  end,
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-word" },
}
return spec
