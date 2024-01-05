---@type LazySpec
local spec = {
  "andymass/vim-matchup",
  config = function()
    -- may set any options here
    vim.g.matchup_matchparen_offscreen = { method = "popup" }
  end,
}
return spec
