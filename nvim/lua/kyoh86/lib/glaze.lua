local Cache = require("kyoh86.lib.cache")

-- Use Neovim's cache directory for persistent storage of settings.
local file = vim.fs.joinpath(vim.fn.stdpath("cache") --[[@as string]], "kyoh86-glaze.json")
local cache = Cache.new(file)

--- Check if a specific setting has been "baked" into the cache.
--- If a setting is "baked", it means its value has been computed and stored for subsequent accesses.
--- @param name string The name of the setting.
--- @return boolean True if the setting exists in the cache, false otherwise.
local function has(name)
  return cache:has(name)
end

--- Store a given setting value directly in the cache, overwriting any existing value.
--- After calling this, the value will be persisted and immediately available for future retrievals.
--- @param name string The name of the setting.
--- @param value any The value to store.
local function set(name, value)
  cache:set(name, value)
end

--- Retrieve a cached setting value. If the value is not yet available, the callback will be invoked once it becomes available.
--- If the retrieved value is invalid for any reason, the callback can call `fail()` to remove it from the cache.
---
--- @param name string The name of the setting.
--- @param callback fun(value: any, fail: fun()) A callback function that receives the value once available.
---        `fail()` can be called within the callback to remove the cached entry if it is deemed invalid.
local function get(name, callback)
  cache:get(name, callback)
end

--- Try to get a value from the cache. If the value is not yet available, this returns nil.
--- @param name string The name of the setting.
local function tryget(name)
  return cache:tryget(name)
end

--- Delete a cached setting value.
---
--- @param name string The name of the setting.
local function del(name)
  cache:del(name)
end

--- Iterate over all stored values in the cache.
local function each()
  return cache:each()
end

--- "Bakes" a setting value into the cache. If the setting is already cached, this does nothing.
--- Otherwise, it computes the value (which may be expensive) and stores it for future use.
--- Use this to speed up initialization by avoiding repeated expensive computations.
---
--- @param name string The name of the setting.
--- @param get_variant fun():any A function that computes the setting value when it isn't already cached.
local function glaze(name, get_variant)
  if cache:has(name) then
    return
  end
  set(name, get_variant())
end

--- Reset all cached settings, clearing all previously stored values.
--- After calling this, you will need to "bake" or set values again.
local function reset()
  cache:clear()
end

return {
  glaze = glaze,
  has = has,
  set = set,
  get = get,
  tryget = tryget,
  del = del,
  each = each,
  reset = reset,
}
