-- GitHub PRの作成
vim.api.nvim_create_user_command("GitHubPullRequest", function(opts)
  local args = opts.args or {}
  local exec = "gh pr new"
  if #args == 1 then
    exec = "gh pr new --title " .. args[1]
  end
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = exec })
end, { nargs = "?", desc = "Create new pull-request in the current repository on GitHub" })

-- GitHub Issue の作成

vim.api.nvim_create_user_command("GitHubIssue", function(opts)
  local args = opts.args or {}
  local exec = "gh issue new"
  if #args == 1 then
    exec = "gh issue new --title " .. vim.fn.shellescape(args[1])
  elseif opts.range > 0 then
    local head = vim.fn.getpos("'<")
    local tail = vim.fn.getpos("'>")
    local lines = vim.fn.getregion(head, tail, { type = vim.fn.visualmode() })
    local title = vim.fn.shellescape(lines[1])
    if #lines > 1 then
      local body = vim.fn.shellescape(table.concat(lines, "\n", 2))
      exec = "gh issue new --title " .. title .. " --body " .. body
    else
      exec = "gh issue new --title " .. title
    end
  end
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = exec })
end, { nargs = "?", range = true, desc = "Create new pull-request in the current repository on GitHub" })

-- オペレータ関数
function _G.create_github_issue_with_title()
  local oldvalue = vim.fn.getreg('"')
  -- モーションの範囲を取得してレジスタにyank
  vim.api.nvim_command("normal! `[v`]y")
  local title = vim.fn.getreg('"')
  title = vim.fn.shellescape(title)

  -- ターミナルでGitHub Issueコマンドを実行
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = "gh issue new --title " .. title })

  -- レジスタの内容を元に戻す
  vim.fn.setreg('"', oldvalue)
end

-- オペレータの設定
vim.api.nvim_set_keymap("n", "<Leader>ghi", "<Cmd>set opfunc=v:lua.create_github_issue_with_title<CR>g@", { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "<Leader>ghi", "<Cmd>set opfunc=v:lua.create_github_issue_with_title<CR>g@", { noremap = true, silent = true })
