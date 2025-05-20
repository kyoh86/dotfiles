---@type LazySpec[]
local specs = { {
  "olimorris/codecompanion.nvim",
  opts = {},
  dependencies = {
    "plenary.nvim",
    "nvim-treesitter",
    "nvim-treesitter-textobjects",
    "mcphub.nvim",
  },
}, {
  "ravitemer/mcphub.nvim",
  build = "bundled_build.lua",
  opts = {
    use_bundled_binary = true,
  },
} }
return specs
