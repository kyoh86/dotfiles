---@type LazySpec
local spec = {
  "Shougo/ddu-source-action",
  dependencies = { "ddu.vim" },
  config = function()
    vim.fn["ddu#custom#patch_global"]({
      kindParams = { action = { quit = true } },
      kindOptions = { action = { defaultAction = "do" } },
    })
  end,
}
return spec
