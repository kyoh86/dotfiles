local AsyncStore = require("kyoh86.lib.async_store")
local file = vim.fs.joinpath(vim.fn.stdpath("cache") --[[@as string]], "kyoh86-glaze.json")
local cache = AsyncStore.new(file)

--- 焼付型の設定: 判定に時間がかかる処理の結果を、初回起動時に焼き付ける。
---
---@param name string 対象設定の名前
---@param get_variant fun():any 判定関数
local function glaze(name, get_variant)
  if cache:has(name) then
    return
  end
  local value = get_variant()
  cache:set(name, value)
  return value
end

--- 焼き付けた内容を設定として使用する
---@param name string 対象設定の名前
---@param callback fun(str)
local function get(name, callback)
  cache:get(name, callback)
end

--- 焼き付けた内容を完全にリセットする
local function reset()
  cache:clear()
end

return {
  glaze = glaze,
  get = get,
  reset = reset,
}
