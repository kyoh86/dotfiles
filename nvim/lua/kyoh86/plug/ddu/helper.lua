local M = {}

function M.map_start(key, name, options)
  local opts = options or {}
  opts.name = name
  vim.keymap.set("n", key, function()
    kyoh86.fa.ddu.start(opts)
  end, { remap = false, desc = "Start ddu source: " .. name })
end

--- map in the named ddu-ui-ff
---@param name string A name of the ui
---@param callback function map function
function M.map_ff(name, callback)
  local group = vim.api.nvim_create_augroup("kyoh86-plug-ddu-ui-ff-map-" .. name, { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "ddu-ff",
    callback = function()
      if vim.b["ddu_ui_name"] == name then
        callback(function(lh, rh)
          vim.keymap.set("n", lh, rh, { nowait = true, remap = false, buffer = true })
        end)
      end
    end,
  })
end

--- Create caller for ddu#ui#do_action
---@param actionName string
---@param params? table
function M.action(actionName, params)
  return function()
    if params then
      kyoh86.fa.ddu.ui.do_action(actionName, params)
    else
      kyoh86.fa.ddu.ui.do_action(actionName)
    end
  end
end

--- Map in the named ddu-ui-ff for "file" kind.
--- it defines <leader>v/<leader>x to edit with splitted window
---@param name string A name of the ui
---@param callback? function remaining map function
function M.map_ff_file(name, callback)
  M.map_ff(name, function(map)
    map("<leader>e", M.action("itemAction", { name = "open" }))
    map("<leader>v", M.action("itemAction", { name = "open", params = { command = "vnew" } }))
    map("<leader>h", M.action("itemAction", { name = "open", params = { command = "new" } }))
    map("<leader>x", M.action("itemAction", { name = "open", params = { command = "new" } }))
    if callback then
      callback(map)
    end
  end)
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
