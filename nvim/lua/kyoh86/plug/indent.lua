---@type LazySpec
local spec = {
  "shellRaining/hlchunk.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local opt = {
      blank = {
        enable = false,
      },
      line_num = {
        enable = false,
      },
      chunk = {
        use_treesitter = false,
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = "▶", -- U+25B6
        },
      },
    }
    if vim.opt.background == "light" then
      kyoh86.ensure("sakura", function(m)
        opt.chunk.style = {
          { fg = m.colors.magenta },
        }
        opt.line_num = {
          style = m.colors.magenta,
        }
      end)
    else
      kyoh86.ensure("momiji", function(m)
        opt.chunk.style = {
          { fg = m.colors.brightmagenta },
        }
        opt.line_num = {
          style = m.colors.brightmagenta,
        }
      end)
    end
    require("hlchunk").setup(opt)
  end,
}
return spec
