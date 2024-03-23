---@type LazySpec
local spec = {
  "kyoh86/denops-ollama.vim",
  dev=true,
  config = function()
    -- vim.fn['denops#server#wait']()
    vim.fn['denops#plugin#wait_async']('ollama', function()
      vim.fn['ollama#custom#patch_func_args']('complete', {model= 'codellama', baseUrl= "http://100.96.204.129:11434"})
    end)
  end,
  dependencies = {"denops.vim"},
}
return spec
