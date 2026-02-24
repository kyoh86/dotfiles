local function restart_all_clients()
  local names = {}
  for _, x in ipairs(vim.lsp.get_clients()) do
    x:stop()
    table.insert(names, x.name)
  end
  for _, name in ipairs(names) do
    vim.lsp.enable(name, true)
  end
end

local function restart_client(name)
  for _, x in ipairs(vim.lsp.get_clients({ name = name })) do
    x:stop()
  end
  vim.lsp.enable(name, true)
end

vim.api.nvim_create_user_command("LspRestart", function(arg)
  if tonumber(arg.nargs) == 0 then
    restart_all_clients()
    return
  end

  for _, name in ipairs(arg.fargs) do
    restart_client(name)
  end
end, {
  nargs = "*",
})
