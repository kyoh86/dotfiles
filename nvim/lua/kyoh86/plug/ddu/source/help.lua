local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "matsui54/ddu-source-help",
  dependencies = { { "ddu.vim" } },
  config = helper.setup_func("help", {
    sources = { { name = "help" } },
    kindOptions = {
      help = {
        defaultAction = "open",
      },
    },
  }, {
    start = {
      key = "<leader>fh",
      desc = "ヘルプ",
    },
  }),
}
return spec
