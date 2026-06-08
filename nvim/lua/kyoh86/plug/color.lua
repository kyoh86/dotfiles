--- ハイライトや色の設定
---@type LazySpec
local spec = {
  {
    "kyoh86/momiji",
    priority = 1000,
    config = function()
      local au = require("kyoh86.lib.autocmd")
      local group = au.group("kyoh86.plug.color", true)
      group:hook("ColorScheme", {
        callback = function(ev)
          -- vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", default = true })
          vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
          vim.cmd("highlight NormalNC guibg=NONE ctermbg=NONE")
        end,
      })
    end,
  },
  {
    "kyoh86/sakura",
    priority = 1001,
    config = function()
      vim.cmd.syntax("enable")
      -- vim.cmd.colorscheme("momiji")
      require("kyoh86.lib.scheme").onBackgroundChanged(function(value)
        if value == "light" then
          vim.cmd.colorscheme("sakura")
        else
          vim.cmd.colorscheme("momiji")
        end
      end, true, { nested = true })
    end,
  },
}
return spec
