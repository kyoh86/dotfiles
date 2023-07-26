---@type LazySpec[]
local spec = {
  {
    "folke/which-key.nvim",
    config = true,
  },
  {
    "kyoh86/vim-gitname",
    init = function()
      vim.api.nvim_create_user_command("YankGitHubURL", function(args)
        kyoh86.fa.gitname.yank.hub_url("branch", args)
      end, { range = true, bang = true })
      vim.api.nvim_create_user_command("YankGitHubPermanentURL", function(args)
        kyoh86.fa.gitname.yank.hub_url("head", args)
      end, { range = true, bang = true })
      vim.api.nvim_create_user_command("YankName", function()
        vim.fn.setreg("+", vim.fn.expand("%"))
      end, { range = true, bang = true })
      vim.api.nvim_create_user_command("YankFullName", function()
        vim.fn.setreg("+", vim.fn.expand("%:p"))
      end, { range = true, bang = true })
      vim.api.nvim_create_user_command("YankGitRel", function()
        kyoh86.fa.gitname.yank.git_rel()
      end, { range = true, bang = true })
      vim.keymap.set("n", "<leader>ygh", [[:call gitname#yank#hub_url("branch", {})]], { silent = true, desc = "copy bufer GitHub URL" })
      vim.cmd([[vnoremap <silent> <leader>ygh :call gitname#yank#hub_url("branch", { "range": 2 })<cr>]]) -- it cannot be mapped by vim.keymap
    end,
  },
  {
    "junegunn/vim-easy-align",
    cmd = { "EasyAlign" },
    keys = { { "ga", "<plug>(EasyAlign)", mode = { "x", "n" }, desc = "EasyAlign" } },
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
