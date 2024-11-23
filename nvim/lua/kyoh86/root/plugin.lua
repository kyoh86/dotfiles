---lazy.nvimを使ってプラグインの管理をする
---@author kyoh86

--- lazy.nvim 本体をインストールする
pcall(function()
  local lazypath = kyoh86.lazydir("lazy.nvim") -- lazydir is defined in preload.lua
  if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
end)

--- lazy.nvim で読み込む
---@type LazyConfig
local opts = {
  dev = { path = require("kyoh86.conf.lazy").dev_path },
  concurrency = 6,
  performance = {
    rtp = {
      disabled_plugins = {
        --- 不要な標準プラグインを無効化
        "gzip",
        "netrwPlugin",
        "netrw",
        "tarPlugin",
        "tar",
        "matchit",
        "tohtml",
        "tutor",
        "zipPlugin",
        "zip",
      },
    },
  },
}

vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("kyoh86-lazy-help-doc", { clear = true }),
  pattern = { "LazyInstall", "LazyUpdate" },
  callback = require("kyoh86.lib.lazy_help").collect,
})

kyoh86.ensure("lazy", function(m)
  m.setup({
    { import = "kyoh86.plug" },
  }, opts)
end)
