local M = {}

---@class GitHubCommentTarget
---@field type "issue"|"pr"
---@field repo? string
---@field number number

--- コメントを付ける
---@param target GitHubCommentTarget
function M.create(target)
  vim.print("hoge")
  local words = {
    "gh",
    target.type,
    "comment",
    "--editor",
    target.number,
  }
  vim.print("fuga")
  if target.repo then
    table.insert(words, "--repo")
    table.insert(words, target.repo)
  end
  vim.print("piyo")
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = table.concat(words, " ") })
  vim.print("tako")
end

return M
