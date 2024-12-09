local helper = require("kyoh86.plug.ddu.helper")
---@type LazySpec
local spec = {
  "kyoh86/ddu-source-local_ddu",
  dependencies = { "ddu.vim" },
  config = function()
    helper.setup("local-ddu", {
      sources = { { name = "local_ddu", options = { defaultAction = "start" } } },
    }, {
      start = {
        key = "<leader><leader>f",
        desc = "Start any local ddu",
      },
    })
  end,
}
return spec
