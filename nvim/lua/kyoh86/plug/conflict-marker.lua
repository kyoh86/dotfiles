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
    vim.keymap.set("n", "[x", "<Plug>(conflict-marker-prev-hunk)", { remap = true })
    vim.keymap.set("n", "]x", "<Plug>(conflict-marker-next-hunk)", { remap = true })
    vim.keymap.set("n", "<leader>gct", "<Plug>(conflict-marker-themselves)", { remap = true, desc = "後を適用する" })
    vim.keymap.set("n", "<leader>gco", "<Plug>(conflict-marker-ourselves)", { remap = true, desc = "前を適用する" })
    vim.keymap.set("n", "<leader>gcb", "<Plug>(conflict-marker-both)", { remap = true, desc = "両方を適用する" })
    vim.keymap.set("n", "<leader>gcB", "<Plug>(conflict-marker-both-rev)", { remap = true, desc = "両方を逆順で適用する" })
    vim.keymap.set("n", "<leader>gcn", "<Plug>(conflict-marker-both-none)", { remap = true, desc = "両方を削除する" })
  end,
}
return spec
