local tmux = require("kyoh86.lib.tmux")

local function with_cwd(cwd, callback)
  if cwd == nil or cwd == "" then
    return callback()
  end

  local prev = vim.fn.getcwd()
  local ok, result = pcall(function()
    vim.cmd.lcd(vim.fn.fnameescape(cwd))
    return callback()
  end)
  pcall(vim.cmd.lcd, vim.fn.fnameescape(prev))
  if not ok then
    error(result)
  end
  return result
end

local function open_buffer(target, opener, cwd)
  if target == nil then
    print("No target found at cursor.")
    return
  end
  local issue_target = target:gsub("%.+$", "")
  return with_cwd(cwd, function()
    local number = issue_target:match("^#(%d+)$")
    local repo, qualified = issue_target:match("^([%w_.-]+/[%w_.-]+)#(%d+)$")
    if number or qualified then
      require("kyoh86.lib.github_issue").open({
        number = number or qualified,
        repo = repo,
        cwd = cwd or vim.fn.getcwd(),
      }, opener)
      tmux.focus_nvim_pane()
    else
      -- TODO: 修正 (多分vim.cmd.findとvim.cmd.sfindでイケる）
      vim.print("opening " .. target)
      if opener.split == "none" then
        vim.cmd.find({ args = { target } })
      elseif opener.split == "left" then
        vim.cmd.sfind({ args = { target }, mods = { vertical = true, split = "aboveleft" } })
      elseif opener.split == "right" then
        vim.cmd.sfind({ args = { target }, mods = { vertical = true, split = "belowright" } })
      elseif opener.split == "rightmost" then
        vim.cmd.sfind({ args = { target }, mods = { vertical = true, split = "botright" } })
      elseif opener.split == "leftmost" then
        vim.cmd.sfind({ args = { target }, mods = { vertical = true, split = "topleft" } })
      elseif opener.split == "above" then
        vim.cmd.sfind({ args = { target }, mods = { split = "aboveleft" } })
      elseif opener.split == "below" then
        vim.cmd.sfind({ args = { target }, mods = { split = "belowright" } })
      elseif opener.split == "top" then
        vim.cmd.sfind({ args = { target }, mods = { split = "topleft" } })
      elseif opener.split == "bottom" then
        vim.cmd.sfind({ args = { target }, mods = { split = "botright" } })
      elseif opener.split == "tab" then
        vim.cmd.sfind({ args = { target }, mods = { tab = "." } })
      end
      tmux.focus_nvim_pane()
    end
  end)
end

--- カーソル下のファイルを関連付けられた外部ファイルで開いたりする
local function open_buffer_cursor(opener)
  local target = vim.fn.expand("<cfile>")
  open_buffer(target, opener)
end

local function with_scratch_cursor(line, col, callback)
  line = line or ""
  local win = vim.api.nvim_get_current_win()
  local prev_buf = vim.api.nvim_win_get_buf(win)
  local prev_cursor = vim.api.nvim_win_get_cursor(win)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
  local ok, result = pcall(function()
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_win_set_cursor(win, { 1, math.min(#line, math.max(0, tonumber(col) or 0)) })
    return callback()
  end)
  pcall(vim.api.nvim_win_set_buf, win, prev_buf)
  pcall(vim.api.nvim_win_set_cursor, win, prev_cursor)
  pcall(vim.api.nvim_buf_delete, buf, { force = true })
  if not ok then
    error(result)
  end
  return result
end

local function open_buffer_at(line, col, opener, cwd)
  local target = with_scratch_cursor(line, col, function()
    return vim.fn.expand("<cfile>")
  end)
  return open_buffer(target, opener, cwd)
end

--- textobjのファイルを関連付けられた外部ファイルで開いたりする
-- TODO: openerを渡せるようにする？
-- local function call_open_buffer_operator()
--   vim.opt.operatorfunc = "v:lua.require'kyoh86.conf.open_buffer'.open_buffer_operator"
--   return "g@"
-- end

--- textobjのファイルを関連付けられた外部ファイルで開いたりするオペレータ
-- TODO: openerを受け取れるようにする？
-- local function open_buffer_operator(type)
--   -- backup
--   local sel_save = vim.o.selection
--   local m_reg = vim.fn.getreg("m", nil)
--
--   vim.o.selection = "inclusive"
--
--   local visual_range
--   if type == "line" then
--     visual_range = "'[V']"
--   else
--     visual_range = "`[v`]"
--   end
--   vim.cmd("normal! " .. visual_range .. '"my')
--   open_buffer(vim.fn.getreg("m", nil))
--
--   -- restore
--   vim.o.selection = sel_save
--   vim.fn.setreg("m", m_reg, nil)
-- end

vim.api.nvim_create_user_command("OpenFileCursor", function(args)
  local opener = { reuse = true }
  if args.smods.vertical then
    if args.smods.aboveleft then
      opener.split = "left"
    elseif args.smods.leftabove then
      opener.split = "left"
    elseif args.smods.belowright then
      opener.split = "right"
    elseif args.smods.botright then
      opener.split = "rightmost"
    elseif args.smods.rightbelow then
      opener.split = "right"
    elseif args.smods.tab then
      opener.split = "tab"
    elseif args.smods.topleft then
      opener.split = "leftmost"
    else
      opener.split = "none"
    end
  else
    if args.smods.aboveleft then
      opener.split = "above"
    elseif args.smods.leftabove then
      opener.split = "above"
    elseif args.smods.belowright then
      opener.split = "below"
    elseif args.smods.botright then
      opener.split = "bottom"
    elseif args.smods.rightbelow then
      opener.split = "below"
    elseif args.smods.tab then
      opener.split = "tab"
    elseif args.smods.topleft then
      opener.split = "top"
    else
      opener.split = "none"
    end
  end
  open_buffer_cursor(opener)
end, { desc = "Open files under the cursor" })

vim.keymap.set("n", "gf", function()
  open_buffer_cursor({ reuse = true, split = "none" })
end, { desc = "Open files under the cursor" })
vim.keymap.set("n", "gfv", function()
  open_buffer_cursor({ reuse = true, split = "left" })
end, { desc = "Open files under the cursor" })
vim.keymap.set("n", "gfx", function()
  open_buffer_cursor({ reuse = true, split = "above" })
end, { desc = "Open files under the cursor" })

-- TODO: キーマップ
-- vim.keymap.set("n", "gb", function()
--   open_buffer_cursor({ reuse = true, split = "none" })
-- end, { desc = "Open files under the cursor" })
-- vim.keymap.set("n", "gbv", function()
--   open_buffer_cursor({ reuse = true, split = "left" })
-- end, { desc = "Open files under the cursor" })
-- vim.keymap.set("n", "gbx", function()
--   open_buffer_cursor({ reuse = true, split = "above" })
-- end, { desc = "Open files under the cursor" })

return {
  open_buffer_at = open_buffer_at,
  open_buffer = open_buffer,
}
