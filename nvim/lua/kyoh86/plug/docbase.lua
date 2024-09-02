---@type LazySpec
local spec = {
  "kyoh86/denops-docbase.vim",
  dependencies = { "denops.vim" },
  config = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "DenopsPluginPost:docbase",
      callback = function()
        vim.fn["docbase#setup#maps"]()
      end,
    })
  end,
}
return spec
