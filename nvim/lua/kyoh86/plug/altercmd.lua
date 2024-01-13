---@type LazySpec
local spec = {
  "kana/vim-altercmd",
  config=function()
    local define = vim.fn["altercmd#define"]
    define("apply", "Apply")
    define("cancel", "Cancel")
  end
}
return spec
