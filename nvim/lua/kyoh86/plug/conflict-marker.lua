---@type LazySpec
local spec = {
  "rhysd/conflict-marker.vim",
  init = function()
    kyoh86.ensure("momiji", function(m)
      vim.api.nvim_set_hl(0, "ConflictMarkerBegin", { bg = m.colors.green, bold = true, blend = 50 })
      vim.api.nvim_set_hl(0, "ConflictMarkerOurs", { fg = m.colors.lightgreen, reverse = true, bold = true, blend = 50 })
      vim.api.nvim_set_hl(0, "ConflictMarkerTheirs", { fg = m.colors.lightblue, reverse = true, bold = true, blend = 50 })
      vim.api.nvim_set_hl(0, "ConflictMarkerEnd", { bg = m.colors.blue, bold = true, blend = 50 })
    end)
    vim.g.conflict_marker_enable_matchit = 0
    vim.g.conflict_marker_enable_mappings = 0
  end,
}
return spec
