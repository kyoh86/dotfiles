local M = {}

local function request_status()
  if vim.fn.exists("*denops#request") == 0 then
    return nil, "denops is not available"
  end
  local ok, data = pcall(vim.fn["denops#request"], "nvim-proxy", "status", {})
  if not ok or type(data) ~= "table" then
    return nil, "denops status request failed"
  end
  return data, nil
end

function M.check()
  vim.health.start("nvim-proxy")

  local status, err = request_status()
  if not status then
    vim.health.warn(err)
    return
  end

  local service = status.service or {}
  if service.ok then
    vim.health.ok(service.message or "service ok")
  else
    vim.health.warn((service.message or "service unavailable") .. " (run :NvimProxyInstall)")
  end

  local proxy = status.proxy or {}
  if proxy.ok then
    vim.health.ok(proxy.message or "proxy ok")
  else
    vim.health.warn(proxy.message or "proxy unavailable")
  end

  local routes = status.routes or {}
  vim.health.info(("routes: %d"):format(#routes))
  for _, entry in ipairs(routes) do
    local pid = entry.pid or 0
    local route_map = entry.routes or {}
    for path, target in pairs(route_map) do
      vim.health.info(("- pid %s %s -> %s"):format(pid, path, target))
    end
  end
end

return M
