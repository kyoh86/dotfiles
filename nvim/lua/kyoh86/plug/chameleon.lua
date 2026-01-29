---@type LazySpec
local spec = {
  "kyoh86/vim-chameleon",
  branch = "support-win",
  enabled = false,
  config = function()
    local au = require("kyoh86.lib.autocmd")
    au.group("kyoh86.plug.chameleon", true):hook("User", {
      pattern = "DenopsPluginPost:chameleon",
      callback = function()
        vim.cmd.ChameleonApply()
      end,
    })
  end,
}
return spec
