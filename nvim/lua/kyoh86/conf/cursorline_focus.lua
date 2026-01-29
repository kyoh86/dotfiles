--- フォーカスされたウィンドウだけCursor lineを表示する
vim.opt.cursorline = true -- Highlight cursor line
vim.opt.cursorlineopt = "number,line" -- Highlight cursor line (only number)

local function enable()
  if vim.bo.buftype == "" then
    vim.opt_local.cursorline = true
  end
end

local function disable()
  if vim.bo.buftype == "" then
    vim.opt_local.cursorline = false
  end
end

local au = require("kyoh86.lib.autocmd")
local group = au.group("kyoh86.conf.cursorline_focus", true)
group:hook("VimEnter", { callback = enable })
group:hook("WinEnter", { callback = enable })
group:hook("BufWinEnter", { callback = enable })
group:hook("WinLeave", { callback = disable })
