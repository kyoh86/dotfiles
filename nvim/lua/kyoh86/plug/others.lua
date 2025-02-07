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
      local path = kyoh86.lazydir("vim-themis") -- lazydir is defined in preload.lua
      vim.env.PATH = vim.env.PATH .. ":" .. path .. "/bin"
    end,
  },
}
return spec
