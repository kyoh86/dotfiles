local wezterm = require("wezterm")

---@class Named
---@field name string

---@class WSLDomain : Named
---@field distribution string

--- Merge two tables
---@generic T : table
---@param t1 T
---@param t2 T
---@return T
local function tbl_merge(t1, t2)
  local merged = {}
  for _, t in pairs({ t1, t2 }) do
    for k, v in pairs(t) do
      merged[k] = v
    end
  end
  return merged
end

---@generic T : Named
---@param name string A name to find it out
---@param list T[]
---@return T
local function find_name(name, list)
  for _, dom in ipairs(list) do
    if dom.name == name then
      return dom
    end
  end
  return nil
end

local default_font_size = 12
local expecting_screen_width = 3840
local function get_font_size()
  local screens = wezterm.gui.screens()
  local active_width = screens.active.width
  if active_width > expecting_screen_width then
    return default_font_size * active_width / expecting_screen_width
  else
    return default_font_size
  end
end

wezterm.on("update-status", function(window, pane)
  if not window:is_focused() then
    return
  end
  window:set_config_overrides({ font_size = get_font_size() })
end)

local keys = {
  { key = "n", mods = "ALT", action = wezterm.action.EmitEvent("open-new-window") },
  { key = "l", mods = "ALT", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|DOMAINS" }) },
  { key = "p", mods = "ALT", action = wezterm.action.ActivateCommandPalette },
}

local function build_domains()
  ---@type WSLDomain[]
  local wsl_domains = wezterm.default_wsl_domains()

  local config = {
    unix_domains = {},
    ssh_domains = {},
  }

  local arch = find_name("WSL:ArchLinux", wsl_domains)
  if arch ~= nil then
    table.insert(wsl_domains, 1, tbl_merge(arch, { name = "WSL:Arch:Neovim", default_prog = { "/bin/zsh", "-l", "-c", "nvim" }, default_cwd = "~" }))
    table.insert(keys, { key = "x", mods = "SHIFT|ALT", action = wezterm.action.SpawnCommandInNewWindow({ label = "Start new ArchLinux Window", args = {}, domain = { DomainName = "WSL:ArchLinux" } }) })
  end

  local ubuntu = find_name("WSL:Ubuntu-24.04", wsl_domains)
  if ubuntu ~= nil then
    table.insert(wsl_domains, 1, tbl_merge(ubuntu, { name = "WSL:Ubuntu:Neovim", default_prog = { "/bin/zsh", "-l", "-c", "nvim" }, default_cwd = "~" }))
    table.insert(keys, { key = "u", mods = "SHIFT|ALT", action = wezterm.action.SpawnCommandInNewWindow({ label = "Start new Ubuntu Window", args = {}, domain = { DomainName = "WSL:Ubuntu" } }) })
    config.default_domain = "WSL:Ubuntu:Neovim"
  else
    config.default_prog = { "nvim" }
  end

  config.wsl_domains = wsl_domains
  return config
end

wezterm.on("open-new-window", function(window, pane)
  wezterm.mux.spawn_window({ domain = { DomainName = pane:get_domain_name() } })
end)

return tbl_merge(build_domains(), {
  -- Workaround for https://github.com/wez/wezterm/issues/5263
  enable_wayland = false,

  initial_cols = 120,
  initial_rows = 36,
  font = wezterm.font_with_fallback({ "PlemolJP Console HS", "Symbols Nerd Font Mono" }),
  font_size = default_font_size,
  color_scheme = "momiji",
  hide_tab_bar_if_only_one_tab = true,
  disable_default_mouse_bindings = true,
  window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
  keys = keys,
  mouse_bindings = {
    {
      event = { Down = { streak = 1, button = "Right" } },
      mods = "NONE",
      action = wezterm.action.PasteFrom("Clipboard"),
    },
  },
  adjust_window_size_when_changing_font_size = false,
})
