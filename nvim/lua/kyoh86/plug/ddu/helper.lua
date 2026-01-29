local func = require("kyoh86.lib.func")
local M = {}

local ddu_ui_map = {}

---call mapped function for named ddu-ui
---UNDONE: support |:map-arguments|
---UNDONE: support map-mode
---@param lh string
local function ddu_ui_call_map(lh)
  local ui_name = vim.b["ddu_ui_name"]
  local rh = (ddu_ui_map[ui_name] or {})[lh]
  if type(rh) == "table" then
    vim.fn["ddu#ui#do_action"](rh.action, rh.params)
  elseif type(rh) == "function" then
    rh()
  end
end

---@class kyoh86.plug.ddu.MapParam
---@field action string
---@field params table<string, any>

---@class kyoh86.plug.ddu.Keymap
---@field key string A key to start ddu
---@field modes? string|string[] A mode or modes for key to start ddu
---@field desc? string A description for the key

---@class kyoh86.plug.ddu.Config
---@field start? kyoh86.plug.ddu.Keymap|kyoh86.plug.ddu.Keymap[] A key or keys to start ddu
---@field localmap? table<string, table> Local key maps for actions.
---@field filelike? boolean Set local maps for file-like kind.

---set mapping for named ddu-ui
---@param ui_name string ddu_ui_name
---@param map table<string, kyoh86.plug.ddu.MapParam | fun()>
local function ddu_ui_set_map(ui_name, map)
  ddu_ui_map[ui_name] = vim.tbl_extend("error", ddu_ui_map[ui_name] or {}, map)
end

function M.show_map(ui_name)
  vim.print(ddu_ui_map[ui_name])
end

---@param name string A name of the ddu instance or the local option.
---@param dduopts table<string, any> ddu options.
---@param config kyoh86.plug.ddu.Config additional config
---@return fun()
function M.setup_func(name, dduopts, config)
  return func.bind_all(M.setup, name, dduopts, config)
end

---@param name string A name of the ddu instance or the local option.
---@param dduopts table<string, any> ddu options.
---@param config kyoh86.plug.ddu.Config additional config
function M.setup(name, dduopts, config)
  vim.fn["ddu#custom#patch_local"](name, dduopts)

  if config.start ~= nil then
    local starts = config.start or {}
    if not vim.islist(starts) then
      starts = { starts }
    end
    for _, start in pairs(starts) do
      vim.keymap.set(start.modes and start.modes or "n", start.key, func.bind_all(vim.fn["ddu#start"], { name = name }), { remap = false, desc = start.desc and "[ddu] " .. start.desc or "Start ddu: " .. name })
    end
  end

  local map = config.localmap or {}
  if config.filelike then
    map = vim.tbl_extend("keep", map, {
      ["<leader>e"] = { action = "itemAction", params = { name = "open" } },
      ["<leader>v"] = { action = "itemAction", params = { name = "open", params = { command = "vnew" } } },
      ["<leader>h"] = { action = "itemAction", params = { name = "open", params = { command = "new" } } },
      ["<leader>x"] = { action = "itemAction", params = { name = "open", params = { command = "new" } } },
    })
  end
  if next(map) == nil then
    return
  end

  local au = require("kyoh86.lib.autocmd")
  ddu_ui_set_map(name, map)
  au.group("kyoh86.plug.ddu.helper.ui_ff_map." .. name, true):hook("FileType", {
    pattern = "ddu-ff",
    callback = function(ev)
      local ok, res = pcall(vim.api.nvim_buf_get_var, ev.buf, "ddu_ui_name")
      if not (ok and res == name) then
        return
      end
      for lh in pairs(map) do
        vim.keymap.set("n", lh, function()
          ddu_ui_call_map(lh)
        end, { nowait = true, remap = false, buffer = true })
      end
    end,
  })
end

return M
