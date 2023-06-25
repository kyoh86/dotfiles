local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "shun/ddu-source-buffer",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file" },
  config = function()
    helper.start_by("<leader>fb", "buffer", { sources = { { name = "buffer" } } })
    helper.map_for_file("buffer")
  end,
}
return spec
