local M = {}

local ddu_ui_map = {}

---call mapped function for named ddu-ui
---UNDONE: support |:map-arguments|
---UNDONE: support map-mode
---@param ui_name string ddu_ui_name
---@param lh string
local function ddu_ui_call_map(ui_name, lh)
  local rh = (ddu_ui_map[ui_name] or {})[lh]
  if type(rh) == "table" then
    kyoh86.fa.ddu.ui.do_action(rh.action, rh.params)
  elseif type(rh) == "function" then
    rh()
  end
end

---@class Kyoh86DduHelperMapParam
---@field action string
---@field params table<string, any>

---@class Kyoh86DduHelperConfig
---@field startkey? string|string[] A key or keys to start ddu
---@field localmap? table<string, table> Local key maps for actions.
---@field filelike? boolean Set local maps for file-like kind.

---set mapping for named ddu-ui
---@param ui_name string ddu_ui_name
---@param map table<string, Kyoh86DduHelperMapParam | fun()>
local function ddu_ui_set_map(ui_name, map)
  ddu_ui_map[ui_name] = vim.tbl_extend("error", ddu_ui_map[ui_name] or {}, map)
end

function M.show_map(ui_name)
  vim.print(ddu_ui_map[ui_name])
end

---@param name string A name of the ddu instance or the local option.
---@param dduopts table<string, any> ddu options.
---@param config Kyoh86DduHelperConfig additional config
function M.setup(name, dduopts, config)
  kyoh86.fa.ddu.custom.patch_local(name, dduopts)

  if config.startkey then
    local keys = config.startkey or {}
    if type(keys) == "string" then
      keys = { keys }
    end
    for _, key in pairs(keys) do
      vim.keymap.set("n", key, function()
        kyoh86.fa.ddu.start({ name = name })
      end, { remap = false, desc = "Start ddu: " .. name })
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
  if next(map) ~= nil then
    local group = vim.api.nvim_create_augroup("kyoh86-plug-ddu-ui-ff-map-" .. name, {})
    ddu_ui_set_map(name, map)
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "ddu-ff",
      callback = function()
        for lh in pairs(map) do
          vim.keymap.set("n", lh, function()
            ddu_ui_call_map(vim.b["ddu_ui_name"], lh)
          end, { nowait = true, remap = false, buffer = true })
        end
      end,
    })
  end
end

return M
