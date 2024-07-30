---@type LazySpec
local spec = {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ignore_install = { "all" },
      ensure_installed = { "go", "gomod", "gosum", "gotmpl", "gowork", "typescript" },
      auto_install = true,

      highlight = {
        enable = false,
      },
    })
  end,
}
return spec
