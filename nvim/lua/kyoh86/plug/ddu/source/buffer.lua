local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "shun/ddu-source-buffer",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file" },
  config = function()
    helper.map_start("<leader>fb", { name = "buffer", sources = { { name = "buffer" } } })
    helper.map_ff_file("buffer")
  end,
}
return spec
