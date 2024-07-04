---@type LazySpec
local spec = {
  "thinca/vim-poslist",
  config = function()
    vim.keymap.set("n", "<leader><c-o>", "<plug>(poslist-prev-buf)", { noremap = false })
    vim.keymap.set("n", "<leader><c-i>", "<plug>(poslist-next-buf)", { noremap = false })
  end,
}
return spec
