--- Insertモードから抜けるときにIMEを自動でオフにする
local glaze = require("kyoh86.lib.glaze")

local group = vim.api.nvim_create_augroup("kyoh86-conf-ime", {})
glaze.get_async("os_uname_sysname", function(
  sysname,
  _ --[[fail]]
)
  local ime = glaze.ensure("ime", function()
    if sysname.sysname == "Linux" then
      if os.getenv("WSL_DISTRO_NAME") ~= "" then
        if vim.fn.executable("zenhan.exe") == 1 then
          return "zenhan"
        end
      else
        if vim.fn.executable("ibus") == 1 then
          return "ibus"
        elseif vim.fn.executable("fcitx-remote") == 1 then
          return "fcitx"
        end
      end
    elseif sysname.sysname == "Darwin" then
      return "mac"
    end
    return ""
  end)
  if ime == "zenhan" then
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = group,
      command = "silent! !zenhan.exe 0",
    })
  elseif ime == "ibus" then
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = group,
      command = "silent! !ibus engine 'xkb:us::eng'",
    })
  elseif ime == "fcitx" then
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = group,
      command = "silent! !fcitx-remote -c",
    })
  elseif ime == "mac" then
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = group,
      command = [[silent! !osascript -e 'tell application "System Events"' -e 'key code 102' -e 'end tell']],
    })
  end
end)
