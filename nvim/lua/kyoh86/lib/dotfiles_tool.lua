return function(name)
  local config = vim.env.XDG_CONFIG_HOME
  if not config or config == "" then
    config = vim.fn.expand("~/.config")
  end
  return vim.fs.joinpath(config, "dotfiles-tool", "dest", name)
end
