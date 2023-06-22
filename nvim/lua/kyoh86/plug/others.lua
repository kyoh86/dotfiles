---@type LazySpec
local spec = {
  {
    "folke/which-key.nvim",
    config = true,
  },
  {
    "kyoh86/vim-gitname",
    init = function()
      vim.api.nvim_create_user_command("YankGitHubURL", function(args)
        vim.fa.gitname.yank.git_hub_url("branch", args)
      end, { range = true, bang = true })
      vim.api.nvim_create_user_command("YankName", function(args)
        vim.fn.setreg("+", vim.fn.expand("%"))
      end, { range = true, bang = true })
      vim.api.nvim_create_user_command("YankFullName", function(args)
        vim.fn.setreg("+", vim.fn.expand("%:p"))
      end, { range = true, bang = true })
      vim.keymap.set("n", "<leader>ygh", [[:call gitname#yank#git_hub_url("branch", {})]], { silent = true, desc = "copy bufer GitHub URL" })
      vim.cmd([[vnoremap <silent> <leader>ygh :call gitname#yank#git_hub_url("branch", { "range": 2 })<cr>]]) -- it cannot be mapped by vim.keymap
    end,
  },
  {
    "kyoh86/curtain.nvim",
    keys = { { "<leader>wr", "<plug>(curtain-start)", desc = "resize current window" } },
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
    "chentoast/marks.nvim",
    opts = { cyclic = true },
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
    "previm/previm", -- previous some file-types
    dependencies = { "tyru/open-browser.vim" },
  },
  {
    "tyru/open-browser-github.vim",
    cmd = { "OpenGithubFile", "OpenGithubIssue", "OpenGithubProject", "OpenGithubPullReq" },
    dependencies = { "tyru/open-browser.vim" },
  },
  {
    "bfrg/vim-jq",
    config = function()
      table.insert(vim.g.markdown_fenced_languages, "jq")
    end,
  },
  {
    "kyoh86/vim-jsonl",
    config = function()
      table.insert(vim.g.markdown_fenced_languages, "jsonl")
    end,
  },
  "kyoh86/vim-go-scaffold",
  { "kyoh86/vim-go-testfile", ft = "go" },
  { "kyoh86/vim-go-coverage", ft = "go" },
  { "dhruvasagar/vim-table-mode", ft = "markdown" },
  "rust-lang/rust.vim",
  {
    "jparise/vim-graphql",
    config = function()
      table.insert(vim.g.markdown_fenced_languages, "graphql")
    end,
  },
  "glench/vim-jinja2-syntax",
  "briancollins/vim-jst",
  { "cespare/vim-toml", branch = "main" },
  "leafgarland/typescript-vim",
  "pangloss/vim-javascript",
  "delphinus/vim-firestore",
  -- for Plugin Development      ==================================================
  { "prabirshrestha/async.vim", cmd = "AsyncEmbed" },
  { "vim-jp/vital.vim", cmd = "Vitalize" },
  { "lambdalisue/vital-Whisky", cmd = "Vitalize" },
  {
    "thinca/vim-themis",
    config = function()
      local path = lazydir("vim-themis") -- lazydir is defined in preload.lua
      vim.env.PATH = vim.env.PATH .. ":" .. path .. "/bin"
    end,
  },
}
return spec
