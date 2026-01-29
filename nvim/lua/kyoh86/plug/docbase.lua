---@type LazySpec
local spec = {
  "kyoh86/denops-docbase.vim",
  dependencies = { "denops.vim" },
  config = function()
    local au = require("kyoh86.lib.autocmd")
    au.group("kyoh86.plug.docbase", true):hook("User", {
      pattern = "DenopsPluginPost:docbase",
      callback = require("kyoh86.lib.func").vind_all(vim.fn["docbase#setup#maps"]),
    })
  end,
}
return spec
