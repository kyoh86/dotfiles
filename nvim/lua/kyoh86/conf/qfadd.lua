vim.api.nvim_create_user_command("QfAdd", function(opts)
  local filename = vim.fn.expand("%:p")
  local list = {}
  for lnum = opts["line1"], opts["line2"] do
    local text = vim.fn.getline(lnum)
    if vim.fn.trim(text) ~= "" then
      table.insert(list, { filename = filename, lnum = lnum, text = text })
    end
  end
  local action = "a"
  local hidden = false
  for _, arg in pairs(opts.fargs) do
    if arg == "-reset" or arg == "-r" then
      if action ~= " " then
        action = "r"
      end
    elseif arg == "-hidden" or arg == "-h" then
      hidden = true
    elseif arg == "-new" or arg == "-n" then
      action = " "
    end
  end
  vim.fn.setqflist(list, action)
  if not hidden then
    vim.cmd.copen()
  end
end, { force = true, range = true, nargs = "*" })
vim.cmd([[ cabbrev <expr> Qfadd (getcmdtype() ==# ":" && getcmdline() ==# "Qfadd") ? "QfAdd" : "Qfadd" ]])
vim.keymap.set({ "n", "v" }, "<leader>qa", "<cmd>QfAdd<cr>", { remap = false, desc = "Quickfixにカーソル位置を追加する" })
