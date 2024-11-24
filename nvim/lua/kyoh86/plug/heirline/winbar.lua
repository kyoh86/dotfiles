--- Winbarの設定
local conditions = require("heirline.conditions")
local palette = require("kyoh86.plug.heirline.palette")
local File = require("kyoh86.plug.heirline.file")
local Ruler = require("kyoh86.plug.heirline.ruler")
local Diagnostics = require("kyoh86.plug.heirline.diagnostics")

return {
  init = function(self)
    self.mode_colors = palette.mode_colors()
  end,
  {
    {
      {
        File,
        Ruler,
        hl = function(self)
          if conditions.is_active() then
            return { fg = "foreground", bg = self.mode_colors.deep }
          else
            return { fg = "gradation2", bg = "gradation4" }
          end
        end,
      },
      {
        -- ファイル名の終端
        provider = "\u{E0BC}", -- 
        hl = function(self)
          if conditions.is_active() then
            return { fg = self.mode_colors.deep, bg = self.mode_colors.bright }
          else
            return { fg = "gradation4", bg = "gradation2" }
          end
        end,
      },
    },

    { provider = "%=" },

    { provider = "%=" },

    Diagnostics,

    hl = function(self)
      if conditions.is_active() then
        return { fg = "background", bg = self.mode_colors.bright }
      else
        return { fg = "gradation4", bg = "gradation2" }
      end
    end,
  },
}
