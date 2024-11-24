--- ハイライトや色の設定
---@type LazySpec
local spec = {
  {
    "kyoh86/momiji",
    priority = 1000,
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
