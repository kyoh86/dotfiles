---lazy.nvimを使ってプラグインの管理をする
---@author kyoh86

--- lazy.nvim 本体をインストールする
pcall(function()
  local lazypath = lazydir("lazy.nvim") -- lazydir is defined in preload.lua
  if not vim.loop.fs_stat(lazypath) then
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

--- 不要な標準プラグインを無効化
vim.g.loaded_gzip = 1
vim.g.loaded_matchit = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tar = 1

--- lazy.nvim で読み込む
---@type LazyConfig
local opts = {
  dev = { path = require("kyoh86.conf.lazy").dev_path },
}
ensure("lazy", function(m)
  m.setup({
    { import = "kyoh86.plug" },
  }, opts)
end)

--- 必要な標準プラグインを有効化
vim.cmd([[
    packadd cfilter
]])
