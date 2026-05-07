---@type LazySpec
local spec = {
  "christoomey/vim-tmux-navigator",
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function()
    -- See: tmux/pane.conf
    vim.keymap.set("n", "<c-w><c-h>", "<cmd>TmuxNavigateLeft<cr>", { silent = true, remap = false })
    vim.keymap.set("n", "<c-w>h", "<cmd>TmuxNavigateLeft<cr>", { silent = true, remap = false })
    vim.keymap.set("n", "<c-w><c-j>", "<cmd>TmuxNavigateDown<cr>", { silent = true, remap = false })
    vim.keymap.set("n", "<c-w>j", "<cmd>TmuxNavigateDown<cr>", { silent = true, remap = false })
    vim.keymap.set("n", "<c-w><c-k>", "<cmd>TmuxNavigateUp<cr>", { silent = true, remap = false })
    vim.keymap.set("n", "<c-w>k", "<cmd>TmuxNavigateUp<cr>", { silent = true, remap = false })
    vim.keymap.set("n", "<c-w><c-l>", "<cmd>TmuxNavigateRight<cr>", { silent = true, remap = false })
    vim.keymap.set("n", "<c-w>l", "<cmd>TmuxNavigateRight<cr>", { silent = true, remap = false })
  end,
}
return spec
