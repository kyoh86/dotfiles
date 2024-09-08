---@type LazySpec
local spec = {
  "kyoh86/denops-docbase.vim",
  dependencies = { "denops.vim" },
  config = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "DenopsPluginPost:docbase",
      callback = require("kyoh86.lib.func").vind_all(vim.fn["docbase#setup#maps"]),
    })
  end,
}
return spec
