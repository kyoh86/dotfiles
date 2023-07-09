---lazy.nvimを使ってプラグインの管理をする
---@author kyoh86

--- lazy.nvim 本体をインストールする
pcall(function()
  local lazypath = kyoh86.lazydir("lazy.nvim") -- lazydir is defined in preload.lua
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

--- lazy.nvim で読み込む
---@type LazyConfig
local opts = {
  dev = { path = require("kyoh86.conf.lazy").dev_path },
  performance = {
    rtp = {
      disabled_plugins = {
        --- 不要な標準プラグインを無効化
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "netrw",
        "tarPlugin",
        "tar",
        "tohtml",
        "tutor",
        "zipPlugin",
        "zip",
      },
    },
  },
}
kyoh86.ensure("lazy", function(m)
  m.setup({
    { import = "kyoh86.plug" },
  }, opts)
end)
