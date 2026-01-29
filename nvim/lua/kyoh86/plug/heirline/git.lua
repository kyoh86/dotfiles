--- feline(statusline)にCWDのGit情報を表示する

local stat = {}
local watch_handler = assert(vim.uv.new_fs_event())
local timer_handler = assert(vim.uv.new_timer())
local gitdir = ""
local defer = require("kyoh86.lib.defer")

local function notify_update_core()
  vim.api.nvim_exec_autocmds("User", { pattern = "UpdateHeirlineGitStatus" })
  vim.cmd.redrawstatus()
end

local notify_update_debounced, _ = defer.debounce_trailing(notify_update_core, 500)

local function notify_update()
  if notify_update_debounced == nil then
    return -- エラーはlib/defer.luaですでに吐いてるので要らない
  end
  notify_update_debounced()
end

local function start_timer()
  timer_handler:start(5000, 5000, vim.schedule_wrap(notify_update))
end

local function stop_timer()
  timer_handler:stop()
end

local function start_watching()
  if not vim.fn.filereadable(gitdir) then
    return
  end
  vim.uv.fs_event_start(
    watch_handler,
    gitdir .. "/index",
    {},
    vim.schedule_wrap(function(err, _, _)
      if err then
        vim.notify("failed to watch git-path: " .. err, vim.log.levels.WARN)
        return
      end
      notify_update()
    end)
  )
end

local function stop_watching()
  watch_handler:stop()
end

local au = require("kyoh86.lib.autocmd")
local group = au.group("kyoh86.plug.heirline.git", true)

group:hook("DirChangedPre", {
  pattern = "global",
  callback = stop_watching,
})

group:hook("DirChanged", {
  pattern = "global",
  callback = function(ev)
    notify_update()
    gitdir = ev.file .. "/.git"
    start_watching()
  end,
})

group:hook("User", {
  pattern = "Kyoh86TermNotifReceived:precmd:*",
  callback = require("kyoh86.lib.func").vind_all(notify_update),
})

group:hook({ "FileChangedShellPost", "FileWritePost", "BufWritePost", "TermLeave", "ModeChanged" }, {
  callback = notify_update,
})

group:hook("VimLeavePre", {
  callback = stop_timer,
})

start_timer()

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

local ERROR_NOT_GIT_REPOSITORY = "fatal: not a git repository"

local function get_git_stat(path)
  stop_watching()
  local completed = vim
    .system({ "git", "status", "--porcelain", "--branch", "--ahead-behind", "--untracked-files", "--renames" }, {
      cwd = path,
      text = true,
    })
    :wait()
  start_watching()
  local info = { has_git = false, ahead = 0, behind = 0, unmerged = 0, untracked = 0, staged = 0, unstaged = 0, dirty = false }
  if completed.code ~= 0 then
    if string.sub(completed.stderr, 1, string.len(ERROR_NOT_GIT_REPOSITORY)) == ERROR_NOT_GIT_REPOSITORY then
      return info
    end
    local msg = "failed to call git-status (code: " .. completed.code .. ") " .. completed.stderr
    vim.print(msg)
    return info
  end
  for _, file in next, vim.fn.split(completed.stdout, "\n") do
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
    provider = function()
      local s = stat[key]
      if signif(s) then
        return prefix .. s --󰛄 x
      end
    end,
  }
end

local Padding = { provider = " " }

local LocalBranch = {
  provider = function()
    -- local
    if stat.branch ~= nil then
      return "\u{F418}" .. stat.branch
    end
  end,
}

local RemoteBranch = {
  provider = function()
    -- remote
    if stat.remote ~= nil then
      return " \u{F427}" .. stat.remote
    else
      return " \u{F0674} "
    end
  end,
}

local StatAhead = numeric_stat_module("\u{EAA1}", "ahead") -- x
local StatBehind = numeric_stat_module("\u{EA9A}", "behind") -- x
local StatUnmerged = numeric_stat_module("\u{F06C4} ", "unmerged") --󰛄 x
local StatStaged = numeric_stat_module("\u{F012C} ", "staged") -- 󰄬 x
local StatUnstaged = numeric_stat_module("\u{F0415} ", "unstaged") -- 󰐕 x
local StatUntracked = numeric_stat_module(" \u{F0205} ", "untracked") -- 󰈅 x

local status = {
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
      StatUnmerged,
      StatStaged,
      StatUnstaged,
      StatUntracked,
      Padding,

      hl = { fg = "yellow", bg = "background", bold = true },
      condition = function()
        return stat.dirty
      end,
    },
    condition = function()
      stat = get_git_stat(vim.fn.getcwd())
      return stat.has_git
    end,
  },
  update = {
    "User",
    pattern = "UpdateHeirlineGitStatus",
  },
}

return status
