--- Statuslineの設定

local palette = require("kyoh86.plug.heirline.palette")

local function setup_heirline()
  palette.set(vim.g.momiji_palette)

  vim.opt.showmode = false -- feline で表示するので、vim標準のモード表示は隠す
  vim.opt.laststatus = 3 -- statuslineにはGlobalな情報だけ表示して、一番下に表示する

  local winbar = require("kyoh86.plug.heirline.winbar")
  local status = require("kyoh86.plug.heirline.status")
  require("heirline").setup({
    opts = {
      disable_winbar_cb = function()
        local rel = vim.api.nvim_win_get_config(0).relative -- never shows winbar for float-win
        return rel and rel ~= ""
      end,
    },
    winbar = winbar,
    statusline = status,
  })
  -- status.setup()
end

---@type LazySpec[]
local spec = { {
  "rebelot/heirline.nvim",
  config = setup_heirline,
  dependencies = { "momiji", "gitsigns.nvim", "nvim-web-devicons", "nvim-navic" },
}, {
  "SmiteshP/nvim-navic",
  opts = {
    separator = " \u{E0BD}",
  },
} }
return spec
