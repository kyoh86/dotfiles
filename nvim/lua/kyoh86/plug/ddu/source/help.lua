local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "matsui54/ddu-source-help",
  config = function()
    local name = "help"
    local source = "help"
    helper.start_by("<leader>fh", name, {
      sources = { { name = source } },
      kindOptions = {
        [source] = {
          defaultAction = "open",
        },
      },
    })
  end,
  dependencies = { { "Shougo/ddu.vim" } },
}
return spec
