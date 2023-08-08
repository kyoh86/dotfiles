---@type LazySpec
local spec = {
  "Shougo/ddu-source-action",
  dependencies = { "ddu.vim" },
  config = function()
    kyoh86.fa.ddu.custom.patch_global({
      kindParams = { action = { quit = true } },
      kindOptions = { action = { defaultAction = "do" } },
    })
  end,
}
return spec
