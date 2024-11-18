local function get_swap_files()
  local dirs = vim.iter(vim.opt.directory:get())
  local files
  local dir
  return function()
    if not files then
      if not dir then
        dir = dirs:next()
        if not dir then
          return
        end
      end
      files = vim
        .iter(vim.fs.dir(dir, { depth = 1 }))
        :filter(function(_, type)
          return type == "file"
        end)
        :map(function(name)
          return vim.fs.joinpath(dir, name)
        end)
      if not files then
        return
      end
    end
    local n = files:next()
    if n then
      return n
    end
  end
end

vim.api.nvim_create_user_command("SwapClean", function()
  for file in vim.iter(get_swap_files()) do
    vim.print("deleting " .. file)
    vim.fs.rm(file)
  end
end, {})

vim.api.nvim_create_user_command("SwapFiles", function()
  for file in vim.iter(get_swap_files()) do
    vim.print(file)
  end
end, {})
