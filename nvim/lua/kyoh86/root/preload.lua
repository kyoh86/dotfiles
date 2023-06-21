--- プラグインの類いを読み込む前に用意する
--- 細かい設定は kyoh86/conf/*.lua を参照

--- requireを安全に実行する
---@param spec string 対象モジュール名
---@param callback function 読み込まれたモジュールを受け取るCallback
_G["ensure"] = function(spec, callback, failed)
  local ok, module = pcall(require, spec)
  if ok then
    if callback then
      return callback(module)
    end
  else
    vim.notify(string.format("failed to load module %q", spec), vim.log.levels.WARN)
    if failed then
      failed()
    end
  end
  return ok, module
end

--- Lazy.nvimでインストールされるもののパス
---@param name string 対象プラグイン名
---@return string ディレクトリパス
_G["lazydir"] = function(name)
  return vim.fs.normalize(vim.fn.stdpath("data") .. "/lazy/" .. name)
end

vim.fa = require("kyoh86.lib.fa")

vim.cmd([[runtime! lua/kyoh86/conf/*.lua]])
