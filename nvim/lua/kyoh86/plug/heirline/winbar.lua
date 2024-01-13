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
            return { fg = "lightwhite", bg = self.mode_colors.deep }
          else
            return { fg = "grayscale2", bg = "grayscale4" }
          end
        end,
      },
      {
        -- ファイル名の終端
        provider = "\u{E0BC}", -- 
        hl = function(self)
          if conditions.is_active() then
            return { fg = self.mode_colors.deep, bg = self.mode_colors.light }
          else
            return { fg = "grayscale4", bg = "grayscale2" }
          end
        end,
      },
      condition = function()
        -- バッファがファイルを開いているかどうか
        local filename = vim.api.nvim_buf_get_name(0)
        return vim.fn.empty(vim.fn.fnamemodify(filename, "%:t")) == 0
      end,
    },

    { provider = "%=" },

    { provider = "%=" },

    Diagnostics,

    hl = function(self)
      if conditions.is_active() then
        return { fg = "black", bg = self.mode_colors.light }
      else
        return { fg = "grayscale4", bg = "grayscale2" }
      end
    end,
  },
}
