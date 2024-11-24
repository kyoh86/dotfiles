--- Statuslineの設定
--
local palette = require("kyoh86.plug.heirline.palette")
local Mode = require("kyoh86.plug.heirline.mode")
local Git = require("kyoh86.plug.heirline.git")

return {
  {
    {
      Mode,
      hl = function(self)
        return { fg = "brightwhite", bg = self.mode_colors.deep }
      end,
    },
    {
      -- 左の終端
      provider = "\u{E0B0}", -- [[ ]]
      hl = function(self)
        return { fg = self.mode_colors.deep, bg = self.mode_colors.bright }
      end,
    },

    {
      -- CWD
      provider = function()
        return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
      end,
    },
    {
      -- 左の終端
      provider = " \u{E0B1}", -- [[ ]]
    },

    { provider = "%=" },

    { provider = "%=" },

    {
      Git,
      -- condition = conditions.is_git_repo,
      hl = { fg = "foreground", bg = "background", bold = true },
    },
    update = { "ColorScheme", "ModeChanged", "DirChanged" },
    init = function(self)
      self.mode_colors = palette.mode_colors()
    end,
    hl = function(self)
      return { fg = "black", bg = self.mode_colors.bright }
    end,
  },
}
