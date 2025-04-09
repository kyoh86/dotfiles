local dev_path_origin = vim.env.HOME .. "/Projects/github.com"
local default_dev_path = dev_path_origin .. "/kyoh86"
local url_pattern = "^https://github%.com/([^/]+)/([^/]+)(%.git)$"

--- Get the path of the plugin in development.
--- @param plugin LazyPlugin
--- @return string
local function dev_path(plugin)
  local url = plugin.url
  if url == nil then
    return default_dev_path
  end
  local owner, name = string.match(url, url_pattern)
  if owner == nil or name == nil then
    return default_dev_path
  end
  return dev_path_origin .. "/" .. owner .. "/" .. name
end
local M = {
  dev_path = dev_path,
}
return M
