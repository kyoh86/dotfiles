---@type LazySpec
local spec = {
  "numToStr/Comment.nvim",
  opts = {
    mappings = false,
  },
  keys = {
    { "<leader>cl", "<plug>(comment_toggle_linewise_current)", mode = "n", remap = false, desc = "toggle line-comment on the region" },
    { "<leader>cl", "<plug>(comment_toggle_linewise_visual)", mode = "x", remap = false, desc = "toggle line-comment on the region" },
    { "<leader>cb", "<plug>(comment_toggle_blockwise_visual)", mode = "x", remap = false, desc = "toggle block-comment on the region" },
  },
}
return spec
