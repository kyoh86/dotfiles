local au = require("kyoh86.lib.autocmd")
local group = au.group("kyoh86.conf.github", true)

-- GitHub 認証情報の復帰またはログイン
group:hook("User", {
  pattern = "DenopsPluginPost:github",
  callback = function()
    require("kyoh86.conf.github.auth").login()
  end,
})

-- GitHub 認証情報をdduに引き渡す
group:hook("User", {
  pattern = "DenopsPluginPost:ddu-source-github",
  callback = function()
    require("kyoh86.conf.github.auth").auth_ddu()
  end,
})

vim.api.nvim_create_user_command("GitHubLogin", function()
  require("kyoh86.conf.github.auth").relogin()
end, { desc = "Login to GitHub" })

-- GitHub PRの作成 コマンド
vim.api.nvim_create_user_command("GitHubPullRequest", function(opts)
  require("kyoh86.conf.github.pr").create_command(opts)
end, { nargs = "?", desc = "Create new pull-request in the current repository on GitHub" })

-- GitHub Issue の作成 コマンド
vim.api.nvim_create_user_command("GitHubIssue", function(opts)
  require("kyoh86.conf.github.issue").create_command(opts)
end, { nargs = "?", range = true, desc = "Create new pull-request in the current repository on GitHub" })

-- GitHub Issue の作成 オペレータ
_G["create_github_issue_with_title"] = require("kyoh86.conf.github.issue").create_operator
vim.api.nvim_set_keymap("n", "<Leader>ghi", "<Cmd>set opfunc=v:lua.create_github_issue_with_title<CR>g@", { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "<Leader>ghi", "<Cmd>set opfunc=v:lua.create_github_issue_with_title<CR>g@", { noremap = true, silent = true })

-- GitHub Issue のコメント追加 コマンド
vim.api.nvim_create_user_command("GitHubIssueComment", function(opts)
  require("kyoh86.conf.github.comment").create({
    type = "issue",
    number = opts.args[1],
  })
end, { nargs = 1, desc = "Create new issue comment in the current repository" })

-- GitHub Pull Request のコメント追加 コマンド
vim.api.nvim_create_user_command("GitHubPullRequestComment", function(opts)
  local target = { type = "pr" }
  if #opts.args > 0 then
    target.number = opts.args[1]
  end
  require("kyoh86.conf.github.comment").create(target)
end, { nargs = "?", desc = "Create new pull-request comment in the current repository" })
