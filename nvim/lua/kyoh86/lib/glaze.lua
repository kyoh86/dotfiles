local Cache = require("kyoh86.lib.cache")

local file = vim.fs.joinpath(vim.fn.stdpath("cache") --[[ @as string]], "kyoh86-glaze.json")
local cache = Cache.new(file)

--- 既に保存済みかチェックする。
---
---@param key string
---@return boolean
local function has(key)
  return cache:has(key)
end

--- 値を保存する。
---
---@param key string
---@param value any
local function set(key, value)
  cache:set(key, value)
end

--- 値を取得する。値が登録されていない場合は登録されたタイミングでcallbackが呼ばれる。
--- 壊れていれば callback 内で fail() すると値を消すことができる。
---
---@param key string
---@param callback fun(value:any, fail:fun())
local function get_async(key, callback)
  cache:get(key, callback)
end

--- 即時取得するが、キャッシュが無ければ nil を返す。
---
---@param key string
---@return any
local function tryget(key)
  return cache:tryget(key)
end

--- 無ければ compute() で作って保存し、その値を返す。
---
---@param key string
---@param compute fun():any
---@return any
local function ensure(key, compute)
  return cache:ensure(key, compute)
end

--- 指定キーの情報を削除する
---
---@param key string
local function del(key)
  cache:del(key)
end

--- 全件をイテレートする
--- 例:
--- for key, value in glaze.each() do
---   vim.print(key, value)
--- end
local function each()
  return cache:each()
end

--- すべての情報を消去する
local function reset()
  cache:clear()
end

return {
  get_async = get_async,
  ensure = ensure,

  has = has,
  set = set,
  tryget = tryget,
  del = del,
  each = each,
  reset = reset,
}
