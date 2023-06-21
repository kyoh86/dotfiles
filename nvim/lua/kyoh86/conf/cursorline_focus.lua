--- フォーカスされたウィンドウだけCursor lineを表示する
vim.opt.cursorline = true -- Highlight cursor line
vim.opt.cursorlineopt = "number,line" -- Highlight cursor line (only number)

local group = vim.api.nvim_create_augroup("kyoh86-conf-cursorline", {})
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

vim.api.nvim_create_autocmd("VimEnter", { group = group, callback = enable })
vim.api.nvim_create_autocmd("WinEnter", { group = group, callback = enable })
vim.api.nvim_create_autocmd("BufWinEnter", { group = group, callback = enable })
vim.api.nvim_create_autocmd("WinLeave", { group = group, callback = disable })
