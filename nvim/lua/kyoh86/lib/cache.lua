local Cache = {}
Cache.__index = Cache

--- Create a new Cache instance backed by a specified file.
--- This will load any previously stored data from the file.
--- @param file string The filepath where the cache will be persisted.
function Cache.new(file)
  local self = setmetatable({
    store = {},
    waiters = {},
    filepath = file,
  }, Cache)
  self:load() -- Load existing data from the file during initialization.
  return self
end

function Cache:set(key, value)
  self.store[key] = value
  if self.waiters[key] then
    for _, waiter in ipairs(self.waiters[key]) do
      waiter(value)
    end
    self.waiters[key] = nil
  end
  self:serialize() -- Save the data to the file when the value set.
end

--- Retrieve a cached value. If the value is not yet available, the callback
--- will be queued and invoked once the value is set. If the returned value is invalid,
--- the callback can invoke `fail()` to remove the entry from the cache.
---
--- @param key string The key associated with the cached value.
--- @param callback fun(value: string, fail: fun()) Called when the value is available. `value` is the cached data, and `fail()` removes the key from the cache if invalid.
function Cache:get(key, callback)
  if self.store[key] then
    callback(self.store[key], function()
      self:del(key)
    end)
    return
  end

  if not self.waiters[key] then
    self.waiters[key] = {}
  end
  table.insert(self.waiters[key], callback)
end

--- Try to get a value. If the value is not yet available, return nil.
--- @param key string The key to get.
--- @return any A value if it is stored, nil otherwise.
function Cache:tryget(key)
  return self.store[key]
end

--- Check whether a value is stored under the given key.
--- @param key string The key to check.
--- @return boolean True if a value is stored, false otherwise.
function Cache:has(key)
  return self.store[key] ~= nil
end

--- Remove the value associated with the specified key.
--- After removal, the updated store is persisted to the file.
function Cache:del(key)
  self.store[key] = nil
  self.waiters[key] = nil
  self:serialize() -- Persist the updated data to the file after deletion.
end

--- Iterate over all stored values in the cache.
function Cache:each()
  return pairs(self.store)
end

--- Clear all stored values, making the cache empty.
--- The change is then persisted to the file.
function Cache:clear()
  self.store = {}
  self.waiters = {}
  self:serialize() -- Persist the now-empty store to the file.
end

--- Serialize the current store and write it to the file in JSON format.
--- If the file does not exist, it will be created.
function Cache:serialize()
  local data = vim.json.encode(self.store)
  local FILE_MODE = 438 -- equivalent to octal 0666 permissions
  local file = vim.uv.fs_open(self.filepath, "w", FILE_MODE)
  if file then
    vim.fn.mkdir(vim.fs.dirname(self.filepath), "p")
    vim.uv.fs_write(file, data, -1)
    vim.uv.fs_close(file)
  else
    error("Failed to open cached file: " .. self.filepath)
  end
end

--- Load previously stored values from the file into the cache.
--- If the file is missing, empty, or invalid, the store defaults to an empty table.
function Cache:load()
  local FILE_MODE = 438 -- equivalent to octal 0666 permissions
  local file = vim.uv.fs_open(self.filepath, "r", FILE_MODE)
  if file then
    local stat = vim.uv.fs_fstat(file)
    if stat then
      local content = vim.uv.fs_read(file, stat.size, 0)
      if content then
        self.store = vim.json.decode(content) or {}
      else
        self.store = {}
      end
    else
      self.store = {}
    end
    vim.uv.fs_close(file)
  else
    self.store = {}
  end
end

return Cache
