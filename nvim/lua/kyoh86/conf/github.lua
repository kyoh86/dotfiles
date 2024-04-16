-- GitHub PRの作成
vim.keymap.set("n", "<leader>ghp", function()
  require("kyoh86.lib.volatile_terminal").split(0, {}, {
    exec = "gh pr new",
  })
end, { remap = false, desc = "Create new pull-request in the current repository on GitHub" })

-- GitHub Issue の作成
vim.keymap.set("n", "<leader>ghi", function()
  require("kyoh86.lib.volatile_terminal").split(0, {}, {
    exec = "gh issue new",
  })
end, { remap = false, desc = "Create new issue in the current repository on GitHub" })

-- GitHub Issue をタイトル付きで作成

-- オペレータ関数
function _G.create_github_issue_with_title()
  -- モーションの範囲を取得してレジスタにyank
  vim.api.nvim_command("normal! `[v`]y")
  local title = vim.fn.getreg('"')
  title = vim.fn.shellescape(title)

  -- ターミナルでGitHub Issueコマンドを実行
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = "gh issue new --title " .. title })

  -- レジスタの内容を元に戻す
  vim.fn.setreg('"', title)
end

-- オペレータの設定
vim.api.nvim_set_keymap("n", "<Leader>ghit", "<Cmd>set opfunc=v:lua.create_github_issue_with_title<CR>g@", { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "<Leader>ghi", "<Cmd>set opfunc=v:lua.create_github_issue_with_title<CR>g@", { noremap = true, silent = true })
