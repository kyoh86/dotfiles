local uv = vim.loop

local AsyncStore = {}
AsyncStore.__index = AsyncStore

function AsyncStore.new(filepath)
  local self = setmetatable({
    store = {},
    waiters = {},
    filepath = filepath,
  }, AsyncStore)
  self:load() -- 初期化時に既存のデータをロード
  return self
end

function AsyncStore:set(key, value)
  self.store[key] = value
  if self.waiters[key] then
    for _, waiter in ipairs(self.waiters[key]) do
      waiter(value)
    end
    self.waiters[key] = nil
  end
  self:serialize() -- 値を設定した後に永続化
end

function AsyncStore:get(key, callback)
  if self.store[key] then
    callback(self.store[key])
    return
  end

  if not self.waiters[key] then
    self.waiters[key] = {}
  end
  table.insert(self.waiters[key], callback)
end

function AsyncStore:has(key)
  return self.store[key] ~= nil
end

function AsyncStore:del(key)
  self.store[key] = nil
  self.waiters[key] = nil
  self:serialize() -- 値を削除した後に永続化
end

function AsyncStore:clear()
  self.store = {}
  self.waiters = {}
  self:serialize() -- すべてクリアした後に永続化
end

function AsyncStore:serialize()
  local data = vim.json.encode(self.store)
  local file = uv.fs_open(self.filepath, "w", 438)
  if file then
    uv.fs_write(file, data, -1)
    uv.fs_close(file)
  else
    error("ファイルを開けませんでした: " .. self.filepath)
  end
end

function AsyncStore:load()
  local file = uv.fs_open(self.filepath, "r", 438)
  if file then
    local stat = uv.fs_fstat(file)
    if stat then
      local content = uv.fs_read(file, stat.size, 0)
      if content then
        self.store = vim.json.decode(content) or {}
      else
        self.store = {}
      end
    else
      self.store = {}
    end
    uv.fs_close(file)
  else
    self.store = {}
  end
end

return AsyncStore
