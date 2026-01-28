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
  if status == nil then
    if err == nil then
      vim.health.warn("unknown request status")
    else
      vim.health.warn(err)
    end
    return
  end

  local service = status.service or {}
  if service.ok then
    vim.health.ok(service.message or "service ok")
  else
    vim.health.warn((service.message or "service unavailable") .. " (run :NvimProxyInstall)")
  end
  local detail = service.detail or {}
  if type(detail.command) == "string" then
    vim.health.info(("service command: %s"):format(detail.command))
    if type(detail.output) == "string" then
      if detail.output == "" then
        vim.health.info("  (no output)")
      else
        for _, line in ipairs(vim.split(detail.output, "\n", { plain = true, trimempty = true })) do
          vim.health.info(("  %s"):format(line))
        end
      end
    end
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
