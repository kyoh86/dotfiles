vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("kyoh86-conf-zsh-result", { clear = true }),
  pattern = "Kyoh86TermNotifReceived:precmd:*",
  callback = function(ev)
    local terms = vim.split(ev.match, ":")
    local ret, bufnr = terms[3], terms[4]
    if bufnr == nil or bufnr == "" then
      -- バッファ番号が分からないときは通知しない
      return
    end
    if vim.fn.bufwinid(0 + bufnr) ~= -1 then
      -- Terminalバッファが隠れてたときだけ通知する
      return
    end
    if ret == "0" then
      vim.notify("Process done in terminal (in buffer " .. bufnr .. ")", vim.log.levels.INFO)
    else
      vim.notify("Process failed(" .. ret .. ") in terminal (in buffer " .. bufnr .. ")", vim.log.levels.ERROR)
    end
  end,
})
