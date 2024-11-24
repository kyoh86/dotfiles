---@type LazySpec
local spec = {
  "kyoh86/vim-chameleon",
  branch = "support-win",
  enabled = false,
  config = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "DenopsPluginPost:chameleon",
      callback = function()
        vim.cmd.ChameleonApply()
      end,
    })
  end,
}
return spec
