--- Goにおいて補完後に変数名が邪魔になることがあるので、削除するショートカットを設定する

--- @return List curpos, string before, string after
local function replace_selection(match, replace)
  local start_pos = vim.fn.getpos("v")
  local start_row, start_col = start_pos[2], start_pos[3]
  local end_pos = vim.fn.getcurpos()
  local end_row, end_col = end_pos[2], end_pos[3]
  if end_row ~= start_row or (end_row == start_row and end_col < start_col) then
    vim.notify("Unsupported visual selection", vim.log.levels.WARN, {})
    return {}, "", ""
  end
  local text = vim.api.nvim_buf_get_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, {})
  local before = text[1]
  if not match(before) then
    vim.notify("No words to remove", vim.log.levels.WARN, {})
    return {}, "", ""
  end
  local after = replace(before)
  text[1] = after
  local curpos = vim.fn.getcursorcharpos(0) -- 0, lnum, col, off, curswant
  vim.api.nvim_buf_set_text(0, start_row - 1, start_col - 1, end_row - 1, end_col, text)
  return curpos, before, after
end

vim.keymap.set({ "s" }, "<plug>(go-cmp-remove-head-word)", function()
  local curpos, before, after = replace_selection(function(before)
    return vim.fn.match(before, [[^\k]]) >= 0
  end, function(before)
    return vim.fn.substitute(before, [[^\k\+\s*]], "", "")
  end)
  if #curpos == 0 then
    return
  end
  local row = curpos[2]
  local col = curpos[3] - (vim.fn.strchars(before) - vim.fn.strchars(after))
  vim.fn.setcursorcharpos({ row, col })
end, { remap = false, desc = "delete first word in the selection" })

vim.keymap.set({ "s" }, "<plug>(go-cmp-remove-continuous-word)", function()
  local curpos, before, _ = replace_selection(function(before)
    return vim.fn.match(before, [[^\k]]) >= 0
  end, function(before)
    return vim.fn.substitute(before, [[^\(\k\+\)\s*.*]], "\\1", "")
  end)
  if #curpos == 0 then
    return
  end
  local row = curpos[2]
  local col = curpos[3] - vim.fn.strchars(before) + 1
  vim.fn.setcursorcharpos({ row, col })
end, { remap = false, desc = "delete continuous word in the selection" })

vim.keymap.set({ "s" }, "<plug>(go-cmp-replace-ref)", function()
  replace_selection(function(before)
    return string.sub(before, 1, 1) == "*"
  end, function(before)
    return "&" .. string.sub(before, 2)
  end)
end, { remap = false, desc = "replace ref mark in the selection" })

vim.keymap.set({ "s" }, "<c-w>", "<plug>(go-cmp-remove-head-word)", { remap = true, buffer = true, desc = "delete first word in the selection" })
vim.keymap.set({ "s" }, "<c-b>", "<plug>(go-cmp-remove-continuous-word)", { remap = true, buffer = true, desc = "delete continuous word in the selection" })
vim.keymap.set({ "s" }, "<c-r>", "<plug>(go-cmp-replace-ref)", { remap = true, buffer = true, desc = "replace ref mark in the selection" })

vim.cmd.compiler("go")

--- teardown ftplugin
--
local undo = vim.b.undo_ftplugin
if undo == nil then
  undo = ""
else
  undo = undo .. "|"
end

vim.b.undo_ftplugin = undo .. "setlocal tabstop< shiftwidth< expandtab<" .. "| sunmap <buffer> <c-w>" .. "| sunmap <buffer> <c-b>" .. "| sunmap <buffer> <c-r>"
