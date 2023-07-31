local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kuuote/ddu-source-mr",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "lambdalisue/mr.vim" },
  config = function()
    helper.setup("mrw", {
      sources = { { name = "mr", params = { kind = "mrw" } } },
    }, {
      startkey = "<leader>fmw",
      filelike = true,
    })
    helper.setup("mrr", {
      sources = { { name = "mr", params = { kind = "mrr" } } },
    }, {
      startkey = "<leader>fmr",
      filelike = true,
    })
    helper.setup("mru", {
      sources = { { name = "mr", params = { kind = "mru" } } },
    }, {
      startkey = "<leader>fmu",
      filelike = true,
    })
  end,
}
return spec
