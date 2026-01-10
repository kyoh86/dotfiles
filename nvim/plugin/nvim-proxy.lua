if vim.g.loaded_nvim_proxy == 1 then
  return
end
vim.g.loaded_nvim_proxy = 1

local function denops_notify(method)
  vim.fn["denops#notify"]("nvim-proxy", method, {})
end

local function denops_request(method)
  if vim.fn.exists("*denops#request") == 0 then
    vim.notify("denops is not available", vim.log.levels.WARN, { title = "nvim-proxy" })
    return nil
  end
  local ok, data = pcall(vim.fn["denops#request"], "nvim-proxy", method, {})
  if not ok then
    vim.notify("nvim-proxy status unavailable", vim.log.levels.WARN, { title = "nvim-proxy" })
    return nil
  end
  return data
end

local function show_status()
  local status = denops_request("status")
  if type(status) ~= "table" then
    return
  end
  local service = status.service or {}
  if service.message then
    vim.api.nvim_echo({ { "nvim-proxy: " .. service.message } }, false, {})
  end
  local proxy = status.proxy or {}
  if proxy.message then
    vim.api.nvim_echo({ { proxy.message } }, false, {})
  end
  local routes = status.routes or {}
  vim.api.nvim_echo({ { ("routes: %d"):format(#routes) } }, false, {})
  for _, entry in ipairs(routes) do
    local pid = entry.pid or 0
    local route_map = entry.routes or {}
    for path, target in pairs(route_map) do
      vim.api.nvim_echo({ { ("- pid %s %s -> %s"):format(pid, path, target) } }, false, {})
    end
  end
end

vim.api.nvim_create_user_command("NvimProxyInstall", function()
  denops_notify("install")
end, {})

vim.api.nvim_create_user_command("NvimProxyStart", function()
  denops_notify("start")
end, {})

vim.api.nvim_create_user_command("NvimProxyEnsure", function()
  denops_notify("ensure")
end, {})

vim.api.nvim_create_user_command("NvimProxyStatus", show_status, {})
