local M = {}

function M.create_command(opts)
  local args = opts.args or {}
  local exec = "gh issue new"
  if #args == 1 then
    exec = "gh issue new --title " .. vim.fn.shellescape(args[1])
  elseif opts.range > 0 then
    local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
    local title = vim.fn.shellescape(lines[1])
    if #lines > 1 then
      local body = vim.fn.shellescape(table.concat(lines, "\n", 2))
      exec = "gh issue new --title " .. title .. " --body " .. body
    else
      exec = "gh issue new --title " .. title
    end
  end
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = exec })
end

-- オペレータ関数
function M.create_operator()
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

return M
