local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kuuote/ddu-source-mr",
  config = function()
    local source = "mr"
    helper.start_by("<leader>fmw", "mrw", { sources = { { name = source, params = { kind = "mrw" } } } })
    helper.map_for_file("mrw")
    helper.start_by("<leader>fmr", "mrr", { sources = { { name = source, params = { kind = "mrr" } } } })
    helper.map_for_file("mrr")
    helper.start_by("<leader>fmu", "mru", { sources = { { name = source, params = { kind = "mru" } } } })
    helper.map_for_file("mru")
  end,
  dependencies = { "Shougo/ddu.vim", "lambdalisue/mr.vim" },
}
return spec
