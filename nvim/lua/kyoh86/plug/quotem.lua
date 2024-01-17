---@type LazySpec
local spec = {
  "kyoh86/vim-quotem",
  keys = {
    { "<leader>yb", "<plug>(quotem-named)", mode = "v", desc = "選択範囲をバッファ名付きのコードブロックでYankする" },
    { "<leader>yB", "<plug>(quotem-fullnamed)", mode = "v", desc = "選択範囲をフルパス付きのコードブロックでYankする" },
    { "<leader>yb", "<plug>(operator-quotem-named)", desc = "バッファ名付きのコードブロックでYankする" },
    { "<leader>yB", "<plug>(operator-quotem-fullnamed)", desc = "フルパス付きのコードブロックでYankする" },
  },
  cmd = { "QuotemGithub", "QuotemBare", "QuotemNamed", "QuotemTailnamed", "QuotemFullnamed" },
  dependencies = { "vim-operator-user" },
}
return spec
