---@type LazySpec
local spec = {
  "kyoh86/vim-cinfo",
  keys = {
    { "<leader>ic", "<plug>(cinfo-show-cursor)", desc = "show informations about the current cursor" },
    { "<leader>ib", "<plug>(cinfo-show-buffer)", desc = "show informations about the current buffer" },
    { "<leader>ih", "<plug>(cinfo-show-highlight)", desc = "show informations about the highlight on the current cursor" },
  },
  cmd = { "CursorInfo" },
}
return spec
