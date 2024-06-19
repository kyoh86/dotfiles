---@type LazySpec
local spec = {
  "kyoh86/denops-docbase.vim",
  branch = "post-template",
  dependencies = { "denops.vim" },
  config = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "DenopsPluginPost:docbase",
      callback = function()
        vim.fn["docbase#setup#maps"]()
        vim.fn["docbase#setup#commands"]()
      end,
    })
  end,
}
return spec
