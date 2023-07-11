local M = {}

--- map ddu#start for keys
---
---@param keys string|string[] lhs of the nmap
---@param name string 'name' of ddu see: |ddu-option|
---@param options DduOptions|fun():DduOptions options
function M.map_start(keys, name, options)
  if type(keys) == "string" then
    keys = { keys }
  end
  for _, key in pairs(keys) do
    vim.keymap.set("n", key, function()
      local opts = options or {}
      if type(opts) == "function" then
        opts = opts()
      end
      opts.name = name
      kyoh86.fa.ddu.start(opts)
    end, { remap = false, desc = "Start ddu source: " .. name })
  end
end

local ddu_ui_map = {}

---call mapped function for named ddu-ui
---UNDONE: support |:map-arguments|
---UNDONE: support map-mode
---@param ui_name string ddu_ui_name
---@param lh string
local function ddu_ui_call_map(ui_name, lh)
  local rh = (ddu_ui_map[ui_name] or {})[lh]
  if type(rh) == "table" then
    local action_name = table.remove(rh, 1)
    kyoh86.fa.ddu.ui.do_action(action_name, rh)
  elseif type(rh) == "function" then
    rh()
  end
end

---set mapping for named ddu-ui
---@param ui_name string ddu_ui_name
---@param map table<string, any>
local function ddu_ui_set_map(ui_name, map)
  ddu_ui_map[ui_name] = vim.tbl_extend("error", ddu_ui_map[ui_name] or {}, map)
end

---map in the named ddu-ui-ff
---@param name string A name of the ui
---@param map table<string, any>
function M.map_ff(name, map)
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

--- Map in the named ddu-ui-ff for "file" kind.
--- it defines <leader>v/<leader>x to edit with splitted window
---@param name string A name of the ui
---@param additional_map? table<string, any> remaining map function
function M.map_ff_file(name, additional_map)
  M.map_ff(
    name,
    vim.tbl_extend("keep", additional_map or {}, {
      ["<leader>e"] = { "itemAction", name = "open" },
      ["<leader>v"] = { "itemAction", name = "open", params = { command = "vnew" } },
      ["<leader>h"] = { "itemAction", name = "open", params = { command = "new" } },
      ["<leader>x"] = { "itemAction", name = "open", params = { command = "new" } },
    })
  )
end

---@alias DduSourceName string
---@alias DduBaseUiParams table<string, any>
---@alias DduBaseSourceParams table<string, any>
---@alias DduBaseActionParams table<string, any>
---@alias DduBaseColumnParams table<string, any>
---@alias DduBaseFilterParams table<string, any>
---@alias DduBaseKindParams table<string, any>
---
---@class DduContext
---@field bufName string
---@field bufNr number
---@field done boolean
---@field input string
---@field maxItems number
---@field mode string
---@field path string
---@field pathHistories string[]
---@field winId number
---
---@class DduCustom
---@field source table<DduSourceName, DduSourceOptions>
---@field option DduOptions
---
---@class DduUserSource
---@field name string
---@field options? DduSourceOptions
---@field params? DduBaseSourceParams
---
---@class DduSourceInfo
---@field name string
---@field index number
---@field path string
---@field kind string
---
---@class DduOptions
---@field actionOptions table<string, DduActionOptions>
---@field actionParams table<string, DduBaseActionParams>
---@field columnOptions table<string, DduColumnOptions>
---@field columnParams table<string, DduBaseColumnParams>
---@field expandInput boolean
---@field filterOptions table<string, DduFilterOptions>
---@field filterParams table<string, DduBaseFilterParams>
---@field input string
---@field kindOptions table<string, DduKindOptions>
---@field kindParams table<string, DduBaseKindParams>
---@field name string
---@field profile boolean
---@field push boolean
---@field refresh boolean
---@field resume boolean
---@field searchPath string
---@field sourceOptions table<DduSourceName, DduSourceOptions>
---@field sourceParams table<DduSourceName, DduBaseSourceParams>
---@field sources DduUserSource[]
---@field sync boolean
---@field ui string
---@field uiOptions table<string, DduUiOptions>
---@field uiParams table<string, DduBaseUiParams>
---@field unique boolean
---
---@alias DduUserOptions table<string, any>
---
---@class DduUiOptions
---@field actions table<string, string>
---@field defaultAction string
---@field persist boolean
---@field toggle boolean
---
---@class DduSourceOptions
---@field actions table<string, string>
---@field columns string[]
---@field converters string[]
---@field defaultAction string
---@field ignoreCase boolean
---@field matcherKey string
---@field matchers string[]
---@field maxItems number
---@field path string
---@field sorters string[]
---@field volatile boolean
---
---@class DduFilterOptions
---@field placeholder? any
---
---@class DduColumnOptions
---@field placeholder? any
---
---@class DduKindOptions
---@field actions table<string, string>
---@field defaultAction string
---
---@class DduActionOptions
---@field quit boolean
---
---@class DduItemHighlight
---@field name string
---@field hl_group string
---@field col number
---@field width number
---
---@class DduItemStatus
---@field size? number
---@field time? number
---
---@class DduItem
---@field word string
---@field display? string
---@field action? any
---@field data? any
---@field highlights? DduItemHighlight[]
---@field status? DduItemStatus
---@field kind? string
---@field level? number
---@field treePath? string
---@field isExpanded? boolean
---@field isTree? boolean
---
---@class DduExpandItem
---@field item DduItem
---@field maxLevel? number
---@field search? string
---
---@alias Denops any
---@alias Context table<string, any>
---
---@class DduActionArguments
---@field denops Denops
---@field context Context
---@field options DduOptions
---@field sourceOptions DduSourceOptions
---@field sourceParams any
---@field kindOptions DduKindOptions
---@field kindParams any
---@field actionParams any
---@field items DduItem[]
---@field clipboard DduClipboard
---@field actionHistory DduActionHistory
---
---@alias DduClipboardAction "none" | "move" | "copy" | "link";
---
---@class DduClipboard
---@field action DduClipboardAction
---@field items DduItem[]
---@field mode string
---
---@class DduActionHistoryActionsField
---@field name string
---@field item? DduItem
---@field dest? string
---
---@class DduActionHistory
---@field actions DduActionHistoryActionsField[]

return M
