local icons = {
  ERROR = "",
  WARN = "",
  INFO = "",
  DEBUG = "",
  TRACE = "✎",
}
---@type LazySpec
local spec = {
  "nvim-mini/mini.notify",
  version = false,
  config = function()
    local notify = require("mini.notify")
    notify.setup({
      content = {
        format = function(notif)
          local time = vim.fn.strftime("%H:%M:%S", math.floor(notif.ts_update))
          local icon = icons.INFO

          for key, value in pairs(vim.log.levels) do
            if value == notif.level then
              icon = icons[key]
            end
          end
          return string.format(" %s %s | %s ", icon, notif.msg, time)
        end,
      },
      window = {
        winblend = 25,
        config = {
          title = "",
          border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
          row = 1,
          -- ╭───╮
          -- │   │
          -- ╰───╯
        },
      },
    })

    vim.api.nvim_set_hl(0, "MiniNotifyBorder", { link = "FloatBorder" })
    vim.api.nvim_set_hl(0, "MiniNotifyNormal", { link = "NormalFloat" })
    vim.api.nvim_set_hl(0, "MiniNotifyTitle", { link = "Title" })
    vim.api.nvim_set_hl(0, "MiniNotifyLspProgress", { link = "DiagnosticInfo" })

    vim.api.nvim_create_user_command("Notifications", function()
      MiniNotify.show_history()
    end, {})
  end,
}
return spec
