local M = {}

--- 指定のIssueにコメントを付ける
---@param number number Issue番号
function M.create(number)
  local exec = string.format("gh issue comment --editor %d", number)
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = exec })
end

--- 指定のリポジトリのIssueにコメントを付ける
---@param repo string リポジトリ
---@param number number Issue番号
function M.create_for(repo, number)
  local exec = string.format("gh --repo %q issue comment --editor %d", repo, number)
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = exec })
end

return M
