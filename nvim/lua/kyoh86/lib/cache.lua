local Cache = {}
Cache.__index = Cache

--- Cache values in the file.
--- @param file string Storing file path.
function Cache.new(file)
  local self = setmetatable({
    store = {},
    waiters = {},
    filepath = file,
  }, Cache)
  self:load() -- Load the data from stored file on init.
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

--- Get a cached value. Wait the value untill it is stored if the value is not stored yet.
--- A value will be passed via callback, but if the value is invalid, it can call fail() to clear the value from cache.
---
---@param key string A key of the value.
---@param callback fun(value: string, fail: fun()) A callback to receive a value.
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

function Cache:has(key)
  return self.store[key] ~= nil
end

function Cache:del(key)
  self.store[key] = nil
  self.waiters[key] = nil
  self:serialize() -- Save the data to the file when the value is deleted.
end

function Cache:clear()
  self.store = {}
  self.waiters = {}
  self:serialize() -- Save the data to the file when the values are cleared.
end

function Cache:serialize()
  local data = vim.json.encode(self.store)
  local file = vim.uv.fs_open(self.filepath, "w", 438)
  if file then
    vim.uv.fs_write(file, data, -1)
    vim.uv.fs_close(file)
  else
    error("ファイルを開けませんでした: " .. self.filepath)
  end
end

function Cache:load()
  local file = vim.uv.fs_open(self.filepath, "r", 438)
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
