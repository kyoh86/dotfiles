vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("kyoh86-conf-zsh-result", { clear = true }),
  pattern = "Kyoh86TermNotifReceived:precmd:*",
  callback = function(ev)
    local terms = vim.split(ev.match, ":")
    local ret, bufnr, command = unpack(terms, 3)
    if not bufnr or bufnr == "" then
      -- バッファ番号が分からないときは通知しない
      return
    end
    if vim.fn.bufwinid(0 + bufnr) ~= -1 then
      -- Terminalバッファが隠れてたときだけ通知する
      return
    end

    local level = vim.log.levels.INFO
    local msg = { "Process" }
    if command and command ~= "" then
      command = vim.fn.trim(vim.base64.decode(command))
      if vim.fn.strcharlen(command) > 30 then
        command = vim.fn.strcharpart(command, 0, 30) .. "..."
      end
      table.insert(msg, "(" .. command .. ")")
    end
    if ret == "0" then
      table.insert(msg, "done")
    else
      table.insert(msg, "failed")
      table.insert(msg, "(" .. ret .. ")")
      level = vim.log.levels.ERROR
    end
    table.insert(msg, "in")
    table.insert(msg, "bufnr:" .. bufnr)
    vim.notify(table.concat(msg, " "), level)
  end,
})
