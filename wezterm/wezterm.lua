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

wezterm.on("open-new-window", function(window, pane)
  wezterm.mux.spawn_window({ domain = { DomainName = pane:get_domain_name() } })
end)

return {
  default_prog = { "/opt/homebrew/bin/tmux", "new-session" },
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
  set_environment_variables = {
    XDG_CONFIG_HOME = "/Users/kyoh86/.config",
  },
  adjust_window_size_when_changing_font_size = false,
}
