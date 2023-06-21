--- Insertモードから抜けるときにIMEを自動でオフにする
local group = vim.api.nvim_create_augroup("kyoh86-conf-ime", {})
if vim.fn.executable("ibus") == 1 then
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    command = "silent! !ibus engine 'xkb:us::eng'",
  })
elseif vim.fn.executable("fcitx-remote") == 1 then
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    command = "silent! !fcitx-remote -c",
  })
elseif vim.fn.executable("osascript") == 1 then
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    command = [[silent! !osascript -e 'tell application "System Events"' -e 'key code 102' -e 'end tell']],
  })
end
