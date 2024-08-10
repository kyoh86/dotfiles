local Cache = require("kyoh86.lib.cache")
local file = vim.fs.joinpath(vim.fn.stdpath("cache") --[[@as string]], "kyoh86-glaze.json")
local cache = Cache.new(file)

--- 設定が焼き付けられているか確認する
---@param name string 対象設定の名前
local function has(name)
  return cache:has(name)
end

--- 設定値を直接セットする
---@param name string 対象設定の名前
---@param value any 対象設定の値
local function set(name, value)
  return cache:set(name, value)
end

--- 焼き付けた内容を設定として使用する
---@param name string 対象設定の名前
---@param callback fun(str)
local function get(name, callback)
  cache:get(name, callback)
end

--- 焼付型の設定: 判定に時間がかかる処理の結果を、初回起動時に焼き付ける。
---
---@param name string 対象設定の名前
---@param get_variant fun():any 判定関数
local function glaze(name, get_variant)
  if cache:has(name) then
    return
  end
  set(name, get_variant())
end

--- 焼き付けた内容を完全にリセットする
local function reset()
  cache:clear()
end

return {
  glaze = glaze,
  has = has,
  set = set,
  get = get,
  reset = reset,
}
