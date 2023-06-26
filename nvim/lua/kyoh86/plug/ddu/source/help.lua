local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "matsui54/ddu-source-help",
  dependencies = { { "Shougo/ddu.vim" } },
  config = function()
    local name = "help"
    local source = "help"
    helper.map_start("<leader>fh", name, {
      sources = { { name = source } },
      kindOptions = {
        [source] = {
          defaultAction = "open",
        },
      },
    })
  end,
}
return spec
