---@type LazySpec[]
local spec = {
  {
    "kyoh86/vim-ripgrep",
    cmd = "Ripgrep",
    init = function()
      vim.cmd([[ cabbrev <expr> Rg (getcmdtype() ==# ":" && getcmdline() ==# "Rg") ? "Ripgrep" : "Rg" ]])
    end,
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
      local group = vim.api.nvim_create_augroup("kyoh86-plug-qfreplace-keymap", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        group = group,
        callback = function()
          --- QuickFixに行番号を表示する
          vim.opt_local.number = true
          vim.keymap.set("n", "<leader>r", "<cmd>Qfreplace<cr>", {
            remap = false,
            buffer = true,
            nowait = true,
            silent = true,
            desc = "replace with quickfix",
          })
        end,
      })
    end,
  },
}
return spec
