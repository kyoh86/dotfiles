local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kuuote/ddu-source-mr",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "lambdalisue/mr.vim" },
  config = function()
    local source = "mr"
    helper.map_start("<leader>fmw", { name = "mrw", sources = { { name = source, params = { kind = "mrw" } } } })
    helper.map_ff_file("mrw")
    helper.map_start("<leader>fmr", { name = "mrr", sources = { { name = source, params = { kind = "mrr" } } } })
    helper.map_ff_file("mrr")
    helper.map_start("<leader>fmu", { name = "mru", sources = { { name = source, params = { kind = "mru" } } } })
    helper.map_ff_file("mru")
  end,
}
return spec
