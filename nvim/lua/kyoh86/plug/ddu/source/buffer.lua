local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "shun/ddu-source-buffer",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file" },
  config = function()
    helper.setup("buffer", { sources = { { name = "buffer" } } }, { startkey = "<leader>fb", filelike = true })
  end,
}
return spec
