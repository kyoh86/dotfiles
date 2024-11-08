vim.api.nvim_create_user_command("SwapClean", function()
  local dirs = vim.opt.directory:get()
  for _, dir in pairs(dirs) do
    for name in vim.iter(vim.fs.dir(dir, {depth= 1})):filter(function(_, type)
      return type == "file"
    end) do
      local file = vim.fs.joinpath(dir, name)
      vim.print("deleting " .. file)
      vim.fs.rm(file)
    end
  end
end, {})
