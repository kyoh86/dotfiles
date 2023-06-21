local meta = {
  __call = function(self, ...)
    local keys = rawget(self, "_keys")
    if #keys < 2 then
      vim.notify("invalid usage: you can use vim.fn instead", vim.log.levels.ERROR)
      return
    end
    return vim.fn[table.concat(keys, "#")](...)
  end,
}

meta.__index = function(self, key)
  local keys = rawget(self, "_keys") or {}
  return setmetatable({ _keys = vim.list_extend(keys, { key }) }, meta)
end

local function_autoloaded = setmetatable({}, meta)
return function_autoloaded
