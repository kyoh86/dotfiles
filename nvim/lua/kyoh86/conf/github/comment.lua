local M = {}

---@class GitHubCommentTarget
---@field type "issue"|"pr"
---@field repo? string
---@field number number

--- コメントを付ける
---@param target GitHubCommentTarget
function M.create(target)
  local words = {
    "gh",
    target.type,
    "comment",
    "--editor",
    target.number,
  }
  if target.repo then
    table.insert(words, "--repo")
    table.insert(words, target.repo)
  end
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = table.concat(words, " ") })
end

return M
