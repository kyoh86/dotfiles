--- Insertモードから抜けるときにIMEを自動でオフにする
vim.uv
  .new_async(vim.schedule_wrap(function()
    local uname = vim.uv.os_uname()
    local group = vim.api.nvim_create_augroup("kyoh86-conf-ime", {})
    if uname.sysname == "Linux" then
      if os.getenv("WSL_DISTRO_NAME") ~= "" then
        -- TODO
      elseif vim.fn.executable("ibus") == 1 then
        vim.api.nvim_create_autocmd("InsertLeave", {
          group = group,
          command = "silent! !ibus engine 'xkb:us::eng'",
        })
      elseif vim.fn.executable("fcitx-remote") == 1 then
        vim.api.nvim_create_autocmd("InsertLeave", {
          group = group,
          command = "silent! !fcitx-remote -c",
        })
      end
    elseif uname.sysname == "Mac" then
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = group,
        command = [[silent! !osascript -e 'tell application "System Events"' -e 'key code 102' -e 'end tell']],
      })
    end
  end))
  :send()
