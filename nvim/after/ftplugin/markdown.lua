--- インデント設定
local indent_size = 4
vim.opt_local.tabstop = indent_size
vim.opt_local.shiftwidth = indent_size

--- markdownのテキスト表示・編集にまつわる設定
vim.opt.isfname:append("@-@")
vim.opt_local.conceallevel = 0
vim.opt_local.formatoptions:remove({ "c" })
vim.opt_local.formatoptions:append({ j = true, r = true, o = true })
vim.opt_local.comments = {
  "nb:>",
  "b:* [ ]",
  "b:* [x]",
  "b:*",
  "b:+ [ ]",
  "b:+ [x]",
  "b:+",
  "b:- [ ]",
  "b:- [x]",
  "b:-",
  "b:1. [ ]",
  "b:1. [x]",
  "b:1.",
}

---@class kyoh86.ft.markdown.CommandArgs
---@field line1 integer
---@field line2 integer

---@param args kyoh86.ft.markdown.CommandArgs
local function get_range(args)
  -- get target range from user command args
  local from = args.line1
  local to = args.line2
  local another = vim.fn.line("v")
  if another == nil then
    return nil, nil
  end
  if from == to and from ~= another then
    if another < from then
      from = another
    else
      to = another
    end
  end
  return from, to
end

--- markdownのCheckbox化・CheckboxのオンオフのToggle
local LIST_PATTERN = [[^\s*\([\*+-]\|[0-9]\+\.\)\s\+]]
local function toggle_checkbox(args)
  local from, to = get_range(args)
  if from == nil or to == nil then
    vim.notify("failed to get range to toggle checkbox", vim.log.levels.ERROR)
    return
  end
  local curpos = vim.fn.getcursorcharpos()
  local lines = vim.fn.getline(from, to)

  for lnum = from, to, 1 do
    local line = lines[lnum - from + 1] --[[@as string]]

    if not vim.regex(LIST_PATTERN):match_str(line) then
      -- not list -> add list marker and blank box
      vim.fn.setline(lnum, vim.fn.substitute(line, [[\v\S|$]], [[- [ ] \0]], ""))
      if lnum == curpos[1] then
        vim.fn.setcursorcharpos({ curpos[1], curpos[2] + 6 })
      end
    elseif vim.regex(LIST_PATTERN .. [[\[ \]\s\+]]):match_str(line) ~= nil then
      -- blank box -> check
      vim.fn.setline(lnum, vim.fn.substitute(line, "\\[ \\]", "[x]", ""))
    elseif vim.regex(LIST_PATTERN .. [[\[x\]\s\+]]):match_str(line) ~= nil then
      -- checked box -> uncheck
      vim.fn.setline(lnum, vim.fn.substitute(line, "\\[x\\]", "[ ]", ""))
    else
      -- list but no box -> add box after list marker
      vim.fn.setline(lnum, vim.fn.substitute(line, [[\S\+]], "\\0 [ ]", ""))
      if lnum == curpos[1] then
        vim.fn.setcursorcharpos({ curpos[1], curpos[2] + 4 })
      end
    end
  end
end

local function remove_checkbox(args)
  local from, to = get_range(args)
  if from == nil or to == nil then
    vim.notify("failed to get range to remove checkbox", vim.log.levels.ERROR)
    return
  end
  local lines = vim.fn.getline(from, to)

  for lnum = from, to, 1 do
    local line = lines[lnum - from + 1] --[[@as string]]

    if vim.regex(LIST_PATTERN .. [[\[[ x]\]\s\+]]):match_str(line) ~= nil then
      -- remove checkbox
      vim.fn.setline(lnum, vim.fn.substitute(line, [[\(]] .. LIST_PATTERN .. [[\)]] .. "\\[[x ]\\]\\s\\+", "\\1", ""))
    end
  end
end

--- Extract outlines from markdown:
--- @author kawarimidoll
--- @cite https://zenn.dev/kawarimidoll/articles/8abb570dac523f
local function sort_qf(a, b)
  return a.lnum > b.lnum and 1 or -1
end

local function show_outline()
  local fname = vim.fn.bufname()

  -- # heading
  vim.cmd([[vimgrep /^#\{1,6} .*$/j ]] .. fname)

  -- heading
  -- ===
  vim.cmd([[vimgrepadd /\zs\S\+\ze\n[=-]\+$/j ]] .. fname)

  local qflist = vim.fn.getqflist()
  if #qflist == 0 then
    vim.cmd.cclose()
    return
  end

  vim.fn.filter(qflist, 'synIDattr(synID(v:val.lnum, v:val.col, 1), "name") != "markdownCodeBlock"')
  vim.fn.sort(qflist, sort_qf)
  vim.fn.setqflist(qflist)
  vim.fn.setqflist({}, "r", { title = fname .. " TOC" })
  vim.cmd.copen()
end

vim.keymap.set("n", "gO", show_outline, { remap = false, buffer = true })

--- Indent list mark on the head of each list-item.
vim.keymap.set("i", "<tab>", function()
  return string.find(vim.api.nvim_get_current_line(), [[%s*[-\*] ]]) == 1 and "<c-t>" or "<tab>"
end, {
  remap = true,
  buffer = true,
  expr = true,
  desc = "Insert one shiftwidth of indent at the start of the current line",
})

vim.keymap.set("i", "<s-tab>", function()
  return string.find(vim.api.nvim_get_current_line(), [[%s*[-\*] ]]) == 1 and "<c-d>" or "<s-tab>"
end, {
  remap = true,
  buffer = true,
  expr = true,
  desc = "Delete one shiftwidth of indent at the start of the current line",
})

vim.api.nvim_buf_create_user_command(0, "MarkdownToggleCheckbox", toggle_checkbox, {
  range = true,
  force = true,
  desc = "Markdownのチェックボックスをトグルする",
})
vim.keymap.set({ "n", "i", "x" }, "<leader>mcc", "<cmd>MarkdownToggleCheckbox<cr>", {
  buffer = true,
  desc = "Markdownのチェックボックスをトグルする",
})

vim.api.nvim_buf_create_user_command(0, "MarkdownRemoveCheckbox", remove_checkbox, {
  range = true,
  force = true,
  desc = "Markdownのチェックボックスを削除する",
})
vim.keymap.set({ "n", "i", "x" }, "<leader>mcd", "<cmd>MarkdownRemoveCheckbox<cr>", {
  buffer = true,
  desc = "Markdownのチェックボックスを削除する",
})

--- teardown ftplugin
--
local undo = vim.b.undo_ftplugin
if undo == nil then
  undo = ""
else
  undo = undo .. "|"
end

vim.b.undo_ftplugin = undo .. "setlocal tabstop< shiftwidth< conceallevel< comments< formatoptions<" .. "| set isfname<" .. "| delcommand -buffer MarkdownToggleCheckbox" .. "| delcommand -buffer MarkdownRemoveCheckbox"
