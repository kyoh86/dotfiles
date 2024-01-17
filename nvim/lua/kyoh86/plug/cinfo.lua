---@type LazySpec
local spec = {
  "kyoh86/vim-cinfo",
  keys = {
    { "<leader>ic", "<plug>(cinfo-show-cursor)", desc = "カーソル情報を表示" },
    { "<leader>ib", "<plug>(cinfo-show-buffer)", desc = "バッファ情報を表示" },
    { "<leader>ih", "<plug>(cinfo-show-highlight)", desc = "ハイライト情報を表示" },
  },
  cmd = { "CursorInfo", "BufferInfo", "HighlightInfo" },
}
return spec
