---@type LazySpec
local spec = {
  "kana/vim-altercmd",
  config = function()
    local define = vim.fn["altercmd#define"]
    define("apply", "Apply")
    define("cancel", "Cancel")
    define("rg", "Ripgrep")
    define("Rg", "Ripgrep")
    define("vh", "vertical help")
    define("vhelp", "vertical help")
  end,
}
return spec
