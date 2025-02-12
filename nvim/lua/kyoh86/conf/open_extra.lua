--- 指定された文字列を元に外部で開く
local function open_extra(target)
  if target == nil then
    print("No target found at cursor.")
    return
  end
  target = string.gsub(target --[[@as string]], [[\.+$]], "")
  if string.match(target, "^#%d+$") then
    vim.print("opening GitHub Issue " .. target)
    -- target が #nnn というIssue番号の場合は、gh を呼んでIssueを開く
    local cmd = { "gh", "issue", "view", "--web", target:sub(2) }
    vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          print("Failed to open issue.")
        end
      end,
    })
  elseif string.match(target, "^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$") then
    vim.print("opening GitHub Repo " .. target)
    -- targetがowner/repoの形ならgh を呼んでリポジトリを開く
    local cmd = { "gh", "repo", "view", "--web", target }
    vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          print("Failed to open repository.")
        end
      end,
    })
  else
    local repo, number = string.match(target, "^([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+)#(%d+)$")
    if repo and number then
      vim.print("opening GitHub Issue " .. target)
      -- targetがowner/repo#nnnの形ならgh を呼んで指定のリポジトリのIssueを開く
      local cmd = { "gh", "issue", "view", "--repo", repo, "--web", number }
      vim.fn.jobstart(cmd, {
        on_exit = function(_, code)
          if code ~= 0 then
            vim.print("Failed to open issue.")
            vim.print(repo, number)
          end
        end,
      })
    else
      vim.print("opening " .. target)
      vim.ui.open(target)
    end
  end
end

--- カーソル下の文字列を関連付けられた外部で開いたりする
local function open_extra_cursor()
  local target = vim.fn.expand("<cfile>")
  open_extra(target)
end

--- textobjの文字列を関連付けられた外部で開いたりする
local function call_open_extra_operator()
  vim.opt.operatorfunc = "v:lua.require'kyoh86.conf.open_extra'.open_extra_operator"
  return "g@"
end

--- textobjの文字列を関連付けられた外部で開いたりするオペレータ
local function open_extra_operator(type)
  -- backup
  local sel_save = vim.o.selection
  local m_reg = vim.fn.getreg("m", nil)

  vim.o.selection = "inclusive"

  local visual_range
  if type == "line" then
    visual_range = "'[V']"
  else
    visual_range = "`[v`]"
  end
  vim.cmd("normal! " .. visual_range .. '"my')
  open_extra(vim.fn.getreg("m", nil))

  -- restore
  vim.o.selection = sel_save
  vim.fn.setreg("m", m_reg, nil)
end

vim.api.nvim_create_user_command("OpenExtraCursor", open_extra_cursor, { desc = "Open extra under the cursor" })
vim.keymap.set("n", "<plug>(open-extra-cursor)", open_extra_cursor, { desc = "Open extra under the cursor" })
vim.keymap.set({ "n", "x" }, "<plug>(open-extra-operator)", call_open_extra_operator, { desc = "Open extra in the textobj", expr = true })

vim.keymap.set("n", "gx", "<plug>(open-extra-cursor)", { desc = "Open extra under the cursor" })

vim.keymap.set({ "n", "x" }, "gz", "<plug>(open-extra-operator)", { desc = "Open extra in the textobj" })

return {
  open_extra_operator = open_extra_operator,
}
