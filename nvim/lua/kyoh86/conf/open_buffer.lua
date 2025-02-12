-- #136
local function open_buffer(target, opener)
  if target == nil then
    print("No target found at cursor.")
    return
  end
  target = string.gsub(target --[[@as string]], [[\.+$]], "")
  if string.match(target, "^#%d+$") then
    vim.print("opening GitHub Issue " .. target)
    -- target が #nnn というIssue番号の場合は、gogh を呼んで現在のリポジトリ名を取得する
    local cmd = { "gogh", "cwd", "--format", "json" }
    local result = vim.system(cmd, { text = true }):wait()
    if result.code ~= 0 or vim.trim(result.stdout) == "" then
      print("Failed to get current project.")
      return
    end
    local project = vim.json.decode(result.stdout)
    vim.fn["denops#github#issue#view"](project.owner, project.name, target:sub(2), opener)
  else
    local owner, repo, number = string.match(target, "^([a-zA-Z0-9_.-]+)/([a-zA-Z0-9_.-]+)#(%d+)$")
    if owner and repo and number then
      vim.print("opening GitHub Issue " .. target)
      vim.fn["denops#github#issue#view"](owner, repo, number, opener)
    else
      -- TODO: 修正 (多分vim.cmd.findとvim.cmd.sfindでイケる）
      vim.print("opening " .. target)
      if opener.split == "none" then
        vim.cmd.find(target)
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
    end
  end
end

--- カーソル下のファイルを関連付けられた外部ファイルで開いたりする
local function open_buffer_cursor(opener)
  local target = vim.fn.expand("<cfile>")
  open_buffer(target, opener)
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

-- return {
--   open_buffer_operator = open_buffer_operator,
-- }
