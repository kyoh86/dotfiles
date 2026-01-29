---@type LazySpec[]
local spec = {
  {
    "kyoh86/vim-ripgrep",
    cmd = "Ripgrep",
    config = function()
      vim.api.nvim_create_user_command("Ripgrep", "call ripgrep#search(<q-args>)", { nargs = "*", complete = "file" })
    end,
  },
  {
    "monaqa/modesearch.vim",
    keys = {
      { "g/", "<Plug>(modesearch-slash)", desc = "search rawstr forward" },
      { "g?", "<Plug>(modesearch-question)", desc = "search rawstr backward" },
      { "<c-x><c-v>", "<Plug>(modesearch-toggle-mode)", mode = "c", desc = "toggle rawstr/default search" },
    },
  },
  {
    "thinca/vim-qfreplace",
    ft = "qf",
    config = function()
      vim.g.qfreplace_no_save = true
      local au = require("kyoh86.lib.autocmd")
      au.group("kyoh86.plug.search.qfreplace_keymap", true):hook("FileType", {
        pattern = "qf",
        callback = function()
          --- QuickFixに行番号を表示する
          vim.opt_local.number = true
          vim.keymap.set("n", "<leader>r", "<cmd>Qfreplace<cr>", {
            remap = false,
            buffer = true,
            nowait = true,
            silent = true,
            desc = "QuickFixの内容を置換する",
          })
        end,
      })
    end,
  },
}
return spec
