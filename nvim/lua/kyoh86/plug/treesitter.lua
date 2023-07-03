---@type LazySpec
local spec = {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    matchup = {
      enable = true, -- mandatory, false will disable the whole extension
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
return spec
