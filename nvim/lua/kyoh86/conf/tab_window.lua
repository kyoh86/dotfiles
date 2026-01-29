--- タブ間を移動したときにウインドウの選択状態を復元する
local au = require("kyoh86.lib.autocmd")

local function tab_leave()
  vim.t.tabwin_last_winnr = vim.api.nvim_get_current_win()
end

local function tab_enter()
  local last_winnr = vim.t.tabwin_last_winnr
  if last_winnr == nil then
    return
  end
  pcall(vim.api.nvim_set_current_win, last_winnr)
end

local group = au.group("kyoh86.conf.tab_window", true)
group:hook("TabLeave", { callback = tab_leave })
group:hook("TabEnter", { callback = tab_enter })

--- タブの切り替え
vim.keymap.set("n", "<leader><tab>", "<Cmd>tabnext<CR>")
vim.keymap.set("n", "<leader><S-tab>", "<Cmd>tabprevious<CR>")
