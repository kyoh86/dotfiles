---@type LazySpec
local spec = {
  "numToStr/Comment.nvim",
  opts = {
    mappings = false,
  },
  keys = {
    { "<leader>cl", "<plug>(comment_toggle_linewise)", mode = "n", remap = false, desc = "toggle line-comment on the region" },
    { "<leader>cb", "<plug>(comment_toggle_blockwise)", mode = "n", remap = false, desc = "toggle block-comment on the region" },
    { "<leader>ccl", "<plug>(comment_toggle_linewise_current)", remap = false, desc = "toggle line-comment on the current line" },
    { "<leader>ccb", "<plug>(comment_toggle_blockwise_current)", remap = false, desc = "toggle block-comment on the current line" },
    { "<leader>cl", "<plug>(comment_toggle_linewise_visual)", mode = "x", remap = false, desc = "toggle line-comment on the region" },
    { "<leader>cb", "<plug>(comment_toggle_blockwise_visual)", mode = "x", remap = false, desc = "toggle block-comment on the region" },
  },
}
return spec
