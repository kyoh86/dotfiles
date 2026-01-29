---@type LazySpec
local spec = {
  "kyoh86/denops-inkdrop.vim",
  config = function()
    local au = require("kyoh86.lib.autocmd")
    au.group("kyoh86.plug.inkdrop", true):hook("User", {
      pattern = "DenopsPluginPost:inkdrop",
      callback = function()
        vim.fn["inkdrop#setup#commands"]()
        vim.fn["inkdrop#setup#maps"]()
      end,
    })
  end,
}
return spec
