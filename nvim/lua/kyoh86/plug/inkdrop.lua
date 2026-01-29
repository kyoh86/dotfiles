---@type LazySpec
local spec = {
  "kyoh86/denops-inkdrop.vim",
  dev = true,
  config = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "DenopsPluginPost:inkdrop",
      callback = function()
        vim.fn["inkdrop#setup#commands"]()
        vim.fn["inkdrop#setup#maps"]()
      end,
    })
  end,
}
return spec
