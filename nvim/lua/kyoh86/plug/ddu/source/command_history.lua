local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "matsui54/ddu-source-command_history",
  dependencies = { "Shougo/ddu.vim" },
  config = function()
    local name = "command-history"
    local source = "command_history"
    helper.map_start("<leader>f;", name, {
      sources = { { name = source } },
      kindOptions = {
        [source] = {
          defaultAction = "execute",
        },
      },
    })

    helper.map_ff(name, function(map)
      map("<leader>e", helper.action("itemAction", { name = "edit" }))
    end)
  end,
}
return spec
