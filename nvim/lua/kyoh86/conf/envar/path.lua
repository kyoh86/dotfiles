local init_path = vim.list_extend(
  vim.list_extend({
    "/usr/local/bin",
    "/usr/local/sbin",
  }, vim.split(vim.env.PATH, ":")),
  {
    "/bin",
    "/usr/bin",
    "/sbin",
    "/usr/sbin",
  }
)
local path = vim.tbl_extend("force", {}, init_path)

--- Pathに追加する
---@path new string  New path to add
local function ins(new)
  table.insert(path, 1, new)
end

--- 環境変数に適用する
local function apply()
  vim.env.PATH = table.concat(path, ":")
end

local function reset()
  path = vim.tbl_extend("force", {}, init_path)
  apply()
end

return {
  reset = reset,
  ins = ins,
  apply = apply,
  home = vim.env.HOME,
}
