local M = {}

---@class kyoh86.conf.github.CommentTarget
---@field type "issue"|"pr"
---@field repo? string
---@field number number

--- コメントを付ける
---@param target kyoh86.conf.github.CommentTarget
function M.create(target)
  local words = {
    "gh",
    target.type,
    "comment",
    "--editor",
    target.number,
  }
  if target.repo ~= nil then
    table.insert(words, "--repo")
    table.insert(words, target.repo)
  end
  require("kyoh86.lib.volatile_terminal").split(0, {}, { exec = table.concat(words, " ") })
end

return M
