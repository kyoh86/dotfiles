--- プラグインの類いを読み込む前に用意する
--- 細かい設定は kyoh86/conf/*.lua を参照

local extension = {}

--- requireを安全に実行する
---@param spec string 対象モジュール名
---@param callback fun(m: any) 読み込まれたモジュールを受け取るCallback
---@param failed? fun() 読み込みに失敗したときに処理を受け取るCallback
extension.ensure = function(spec, callback, failed)
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

--- 焼付型の設定: 判定に時間がかかる処理を、
--- 初回起動時にglaze/syrupからglaze/stainにコピーする形で有効化する
---
--- confの中で呼び出すことで動作する
---
---@param name string 対象設定の名前
---@param get_variant fun():string どのパターンを使用するか判定する関数
extension.glaze = function(name, get_variant)
  if vim.g["kyoh86_glaze_" .. name] == true then
    return
  end
  local variant = get_variant()
  vim.print(string.format("glazing %q with a variant %q", name, variant))
  local conf = vim.fn.stdpath("config") --[[@as string]]
  local src = vim.fs.joinpath(conf, "lua/kyoh86/glaze/syrup", name, variant .. ".lua")
  local dst = vim.fs.joinpath(conf, "lua/kyoh86/glaze/stain", name .. ".lua")
  local raw = vim.fn.readfile(src)
  table.insert(raw, 1, "vim.g.kyoh86_glaze_" .. name .. " = true")
  vim.fn.writefile(raw, dst)
  vim.cmd.luafile(dst)
end

-- 焼き付けた内容を設定として使用する
vim.cmd.runtime({ args = { "lua/kyoh86/glaze/stain/*.lua" }, bang = true })

--- Lazy.nvimでインストールされるもののパス
---@param name string 対象プラグイン名
---@return string ディレクトリパス
extension.lazydir = function(name)
  return vim.fs.normalize(vim.fn.stdpath("data") .. "/lazy/" .. name)
end

vim.treesitter.start = function() end
_G["kyoh86"] = extension
vim.cmd.runtime({ args = { "lua/kyoh86/conf/*.lua" }, bang = true })
