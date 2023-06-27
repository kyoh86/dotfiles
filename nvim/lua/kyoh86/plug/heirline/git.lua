--- feline(statusline)にCWDのGit情報を表示する

--- Split a line which holds branch status from git-stauts-porcelain
--- The line holds a local branch name, remote, ahead and behind commit counts like below.
---     ## main...origin/main [ahead 3, behind 2]
--- Eash words can be dropped if it has no significant value like below.
---     ## main...origin/main [behind 9]
---
---     ## feature-1
---
--- This function will returns branch, remote, ahead and behind for each.
---@param line string  A line of the branch in git-status-porcelain
---@return string, string|nil, number, number
local function split_branch_line(line)
  local words = vim.fn.split(line, "\\.\\.\\.\\|[ \\[\\],]")
  if #words == 2 then
    return words[2], nil, 0, 0
  elseif #words > 3 then
    local info = {}
    local key = ""
    for i, r in ipairs(words) do
      if i > 3 then
        if key ~= "" then
          info[key] = r
          key = ""
        else
          key = r
        end
      end
    end
    return words[2], words[3], info["ahead"], info["behind"]
  else
    return words[2], words[3], 0, 0
  end
end

local function signif(x)
  if x == nil then
    return false
  elseif type(x) == "number" then
    return x ~= 0
  elseif type(x) == "string" then
    local n = tonumber(x)
    if n == nil then
      return x ~= ""
    end
    return n ~= 0
  end
end

local function get_git_stat(path)
  local res = vim.fn.system("git -C '" .. path .. "' status --porcelain --branch --ahead-behind --untracked-files --renames")
  local info = { has_git = false, ahead = 0, behind = 0, unmerged = 0, untracked = 0, staged = 0, unstaged = 0, dirty = false }
  if string.sub(res, 1, 7) == "fatal: " then
    return info
  end
  for _, file in next, vim.fn.split(res, "\n") do
    local staged = string.sub(file, 1, 1)
    local unstaged = string.sub(file, 2, 2)
    local changed = string.sub(file, 1, 2)
    if changed == "##" then
      -- ブランチ名を取得する
      info.branch, info.remote, info.ahead, info.behind = split_branch_line(file)
      info.dirty = info.dirty or signif(info.ahead) or signif(info.behind)
      info.has_git = info.branch ~= ""
    elseif staged == "U" or unstaged == "U" or changed == "AA" or changed == "DD" then
      info.unmerged = info.unmerged + 1
      info.dirty = true
    elseif changed == "??" then
      info.untracked = info.untracked + 1
      info.dirty = true
    else
      if staged ~= " " then
        info.staged = info.staged + 1
        info.dirty = true
      end
      if unstaged ~= " " then
        info.unstaged = info.unstaged + 1
        info.dirty = true
      end
    end
  end
  return info
end

local function numeric_stat_module(prefix, key)
  return {
    provider = function(self)
      local s = self.stat[key]
      if signif(s) then
        return prefix .. s --󰛄 x
      end
    end,
  }
end

local Padding = { provider = " " }

local LocalBranch = {
  provider = function(self)
    -- local
    if self.stat.branch ~= nil then
      return "\u{F418}" .. self.stat.branch
    end
  end,
}

local RemoteBranch = {
  provider = function(self)
    -- remote
    if self.stat.remote ~= nil then
      return " \u{F427}" .. self.stat.remote
    else
      return " \u{F6C8}"
    end
  end,
}

local StatAhead = numeric_stat_module("\u{EAA1}", "ahead") -- x
local StatBehind = numeric_stat_module("\u{EA9A}", "behind") -- x
local StatUnfollow = {
  provider = function(self)
    if self.stat.branch ~= nil and self.stat.remote == nil then
      return "\u{F6C8}" -- x
    end
  end,
}
local StatUnmerged = numeric_stat_module("\u{F06C4} ", "unmerged") --󰛄 x
local StatStaged = numeric_stat_module("\u{F012C} ", "staged") -- 󰄬 x
local StatUnstaged = numeric_stat_module("\u{F0415} ", "unstaged") -- 󰐕 x
local StatUntracked = numeric_stat_module(" \u{F0205} ", "untracked") -- 󰈅 x

return {
  {
    {
      -- Git branch
      Padding,
      LocalBranch,
      RemoteBranch,
    },
    Padding,
    {
      -- Git status
      StatAhead,
      StatBehind,
      StatUnfollow,
      StatUnmerged,
      StatStaged,
      StatUnstaged,
      StatUntracked,
      Padding,

      hl = { fg = "yellow", bg = "black" },
      condition = function(self)
        return self.stat.dirty
      end,
    },
    condition = function(self)
      self.stat = get_git_stat(vim.fn.getcwd())
      return self.stat.has_git
    end,
  },
  update = { "CursorHold", "CursorHoldI", "DirChanged", "FileChangedShellPost", "FileWritePost", "BufWritePost", "TermLeave", "ModeChanged" },
}
