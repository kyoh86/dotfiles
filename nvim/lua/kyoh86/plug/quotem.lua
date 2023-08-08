---@type LazySpec
local spec = {
  "kyoh86/vim-quotem",
  keys = {
    { "<leader>yb", "<plug>(quotem-named)", mode = "v", desc = "copy markdown-quoted text from selection with buffer name" },
    { "<leader>Yb", "<plug>(quotem-fullnamed)", mode = "v", desc = "copy markdown-quoted text from selection with full-name" },
    { "<leader>yb", "<plug>(operator-quotem-named)", desc = "start to copy markdown-quoted text with buffer name" },
    { "<leader>Yb", "<plug>(operator-quotem-fullnamed)", desc = "start to copy markdown-quoted text with full-name" },
  },
  cmd = { "QuotemGithub", "QuotemBare", "QuotemNamed", "QuotemTailnamed", "QuotemFullnamed" },
  dependencies = { "vim-operator-user" },
}
return spec
