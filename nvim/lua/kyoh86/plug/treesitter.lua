---@type LazySpec[]
local specs = { {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    ensure_installed = {
      "bash",
      "css",
      "dockerfile",
      "go",
      "html",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "toml",
      "tsx",
      "typescript",
      "yaml",
    },
    highlight = {
      enable = false,
    },
  },
}, {
  "nvim-treesitter/nvim-treesitter-textobjects",
} }
return specs
