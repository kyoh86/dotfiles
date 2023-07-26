local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "matsui54/ddu-source-help",
  dependencies = { { "Shougo/ddu.vim" } },
  config = function()
    helper.map_start("<leader>fh", {
      name = "help",
      sources = { { name = "help" } },
      kindOptions = {
        help = {
          defaultAction = "open",
        },
      },
    })
  end,
}
return spec
