---@type LazySpec
local spec = {
  "nvim-mini/mini.pick",
  lazy = false,
  dependencies = { "nvim-mini/mini.extra", "lambdalisue/vim-mr" },
  config = function()
    local ui_select = vim.ui.select
    require("mini.pick").setup({
      mappings = {
        choose_marked = "<C-q>",
        toggle_preview = "<C-w>",
      },
    })
    vim.ui.select = function(items, opts, on_choice)
      if opts and opts.kind == "codeaction" then
        return require("mini.pick").ui_select(items, opts, on_choice)
      end
      return ui_select(items, opts, on_choice)
    end

    local function highlight_current()
      local palette = vim.g[(vim.g.colors_name or "") .. "_palette"]
      local hl = { reverse = true, bold = true }
      if palette then
        hl = {
          bg = palette.brightgreen[1],
          fg = palette.black[1],
          ctermbg = palette.brightgreen[2],
          ctermfg = palette.black[2],
          bold = true,
        }
      end
      vim.api.nvim_set_hl(0, "MiniPickMatchCurrent", hl)
    end
    highlight_current()
    require("kyoh86.lib.scheme").onSchemeChanged(highlight_current)
    require("kyoh86.lib.pick").setup()
  end,
}
return spec
