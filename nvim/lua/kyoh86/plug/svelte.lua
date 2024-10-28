---@type LazySpec
local spec = {
  "leafOfTree/vim-svelte-plugin",
  config = function()
    vim.g.vim_svelte_plugin_use_typescript = true
  end,
}
return spec
