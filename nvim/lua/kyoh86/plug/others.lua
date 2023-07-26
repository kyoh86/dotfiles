---@type LazySpec[]
local spec = {
  {
    "folke/which-key.nvim",
    config = true,
  },
  {
    "bfredl/nvim-miniyank",
    keys = {
      { "p", "<plug>(miniyank-autoput)", mode = "", desc = "autoput with miniyank" },
      { "P", "<plug>(miniyank-autoPut)", mode = "", desc = "autoput with miniyank" },
    },
  },
  {
    "kyoh86/curtain.nvim",
    keys = { { "<leader>wr", "<plug>(curtain-start)", desc = "resize current window" } },
  },
  {
    "lambdalisue/guise.vim", -- Enhance $EDITOR behavior in terminal
    dependencies = { "vim-denops/denops.vim" },
  },
  {
    "tyru/capture.vim",
    cmd = "Capture",
  },
  {
    "tyru/open-browser-github.vim",
    cmd = { "OpenGithubFile", "OpenGithubIssue", "OpenGithubProject", "OpenGithubPullReq" },
    dependencies = { "tyru/open-browser.vim" },
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
