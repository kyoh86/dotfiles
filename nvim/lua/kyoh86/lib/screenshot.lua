local uv = vim.loop
local glaze = require("kyoh86.lib.glaze")

local M = {}

local function is_mac()
  return vim.fn.has("macunix") == 1
end

local function is_wsl()
  return os.getenv("WSL_DISTRO_NAME") ~= nil or os.getenv("WSL_INTEROP") ~= nil
end

local function run_cmd(cmd)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out
end

local function normalize_dir(dir)
  if not dir or dir == "" then
    return nil
  end
  return vim.fn.fnamemodify(dir, ":p")
end

local function default_mac_dir()
  local out = run_cmd({ "defaults", "read", "com.apple.screencapture", "location" })
  if out and out[1] and out[1] ~= "" then
    return normalize_dir(out[1])
  end
  return normalize_dir(vim.fn.expand("~/Desktop"))
end

local function wsl_windows_home()
  if vim.fn.executable("wslvar") ~= 0 then
    local out = run_cmd({ "wslvar", "USERPROFILE" })
    if out and out[1] and out[1] ~= "" then
      return out[1]
    end
  end
  if vim.fn.executable("cmd.exe") ~= 0 then
    local out = run_cmd({ "cmd.exe", "/c", "echo", "%USERPROFILE%" })
    if out and out[1] and out[1] ~= "" then
      return out[1]
    end
  end
  return nil
end

local function wsl_to_linux_path(win_path)
  if vim.fn.executable("wslpath") == 0 then
    return nil
  end
  local out = run_cmd({ "wslpath", "-u", win_path })
  if out and out[1] and out[1] ~= "" then
    return out[1]
  end
  return nil
end

local function default_wsl_dir()
  local win_home = wsl_windows_home()
  if not win_home then
    return nil
  end
  local win_screenshots = win_home .. "\\Pictures\\Screenshots"
  return normalize_dir(wsl_to_linux_path(win_screenshots))
end

local function default_dir()
  if is_mac() then
    return default_mac_dir()
  end
  if is_wsl() then
    return default_wsl_dir()
  end
  return nil
end

local function default_patterns()
  if is_mac() then
    return { "Screen Shot", "Screenshot", "スクリーンショット" }
  end
  if is_wsl() then
    return { "Screenshot", "スクリーンショット" }
  end
  return {}
end

local function default_extensions()
  return { ".png", ".jpg", ".jpeg", ".tiff", ".bmp", ".gif" }
end

local function has_extension(name, exts)
  local lower = name:lower()
  for _, ext in ipairs(exts) do
    if lower:sub(-#ext) == ext then
      return true
    end
  end
  return false
end

local function matches_patterns(name, patterns)
  if #patterns == 0 then
    return true
  end
  for _, pat in ipairs(patterns) do
    if name:find(pat, 1, true) then
      return true
    end
  end
  return false
end

local function latest_in_dir(dir, patterns, exts)
  local handle = uv.fs_scandir(dir)
  if not handle then
    return nil
  end
  local latest_path = nil
  local latest_mtime = 0
  while true do
    local name, typ = uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if typ == "file" and has_extension(name, exts) and matches_patterns(name, patterns) then
      local path = dir .. "/" .. name
      local stat = uv.fs_stat(path)
      if stat and stat.mtime and stat.mtime.sec and stat.mtime.sec > latest_mtime then
        latest_mtime = stat.mtime.sec
        latest_path = path
      end
    end
  end
  return latest_path
end

--- 最新のスクリーンショットのパスを返す
--- @param opts? table
--- @return string|nil
--- @return string|nil
function M.latest(opts)
  opts = opts or {}
  local env_dir = os.getenv("SCREENSHOT_DIR")
  local dir = normalize_dir(opts.dir or env_dir)
  if not dir then
    dir = glaze.ensure("lib.screenshot.dir.path", default_dir)
    dir = normalize_dir(dir)
  end
  if not dir then
    return nil, "screenshot dir is not found"
  end
  local patterns = opts.patterns or default_patterns()
  local exts = opts.extensions or default_extensions()
  local path = latest_in_dir(dir, patterns, exts)
  if path then
    return path
  end
  path = latest_in_dir(dir, {}, exts)
  if path then
    return path
  end
  return nil, "screenshot file is not found in " .. dir
end

M.default_dir = default_dir

return M
