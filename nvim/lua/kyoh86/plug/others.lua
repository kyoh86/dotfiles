---@type LazySpec[]
local spec = {
  {
    "kyoh86/curtain.nvim",
    keys = { { "<leader>wr", "<plug>(curtain-start)", desc = "ウインドウをリサイズする" } },
  },
  {
    "lambdalisue/vim-guise", -- Enhance $EDITOR behavior in terminal
    dependencies = { "denops.vim" },
    init = function()
      vim.g["guise#disable_vim"] = true
      vim.g["guise#disable_editor"] = false
      vim.g.guise_edit_opener = "GuiseEdit"
    end,
    config = function()
      vim.api.nvim_create_user_command("GuiseEdit", function(opts)
        if vim.env.TMUX_PANE then
          vim.system({ "tmux", "select-pane", "-t", vim.env.TMUX_PANE }):wait()
        end
        vim.cmd("noswapfile tab drop " .. vim.fn.fnameescape(opts.args))
      end, {
        complete = "file",
        nargs = 1,
      })
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  {
    "tpope/vim-dispatch",
    lazy = true,
  },
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "tyru/capture.vim",
    cmd = "Capture",
  },
  "delphinus/vim-firestore",
  -- for Plugin Development      ==================================================
  { "prabirshrestha/async.vim", cmd = "AsyncEmbed" },
  { "vim-jp/vital.vim", cmd = "Vitalize" },
  { "lambdalisue/vital-Whisky", cmd = "Vitalize" },
  {
    "thinca/vim-themis",
    config = function()
      local envar = require("kyoh86.lib.envar")
      local path = kyoh86.lazydir("vim-themis") -- lazydir is defined in preload.lua
      envar.PATH = envar.PATH .. ":" .. path .. "/bin"
    end,
  },
}
return spec
