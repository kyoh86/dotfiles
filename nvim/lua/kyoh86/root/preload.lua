--- プラグインの類いを読み込む前に用意する
--- 細かい設定は kyoh86/conf/*.lua を参照

--- requireを安全に実行する
---@param spec string 対象モジュール名
---@param callback fun(m: any) 読み込まれたモジュールを受け取るCallback
---@param failed? fun() 読み込みに失敗したときに処理を受け取るCallback
local function ensure(spec, callback, failed)
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
local function lazydir(name)
  return vim.fs.normalize(vim.fn.stdpath("data") .. "/lazy/" .. name)
end

_G["kyoh86"] = {
  ensure = ensure,
  lazydir = lazydir,
}

-- disable treesitter
vim.treesitter.start = function() end

vim.cmd.runtime({ args = { "lua/kyoh86/conf/*.lua" }, bang = true })
