---@type LazySpec
local spec = {
  "numToStr/Comment.nvim",
  opts = {
    mappings = false,
  },
  keys = {
    { "<leader>cl", "<plug>(comment_toggle_linewise_current)", mode = "n", remap = false, desc = "行コメントをトグルする" },
    { "<leader>cl", "<plug>(comment_toggle_linewise_visual)", mode = "x", remap = false, desc = "行コメントをトグルする" },
    { "<leader>cb", "<plug>(comment_toggle_blockwise_visual)", mode = "x", remap = false, desc = "ブロックコメントをトグルする" },
  },
}
return spec
