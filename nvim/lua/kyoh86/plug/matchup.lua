---@type LazySpec
local spec = {
  "andymass/vim-matchup",
  config = function()
    -- may set any options here
    vim.g.matchup_matchparen_offscreen = {}
  end,
  event = "VeryLazy",
}
return spec
