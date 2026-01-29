local autocmd = {}

---@alias kyoh86.lib.autocmd.Events vim.api.keyset.events|vim.api.keyset.events[]
---@alias kyoh86.lib.autocmd.CreateOpts vim.api.keyset.create_autocmd

---@class kyoh86.lib.autocmd.Augroup
---@field group integer
---@field hook fun(self: kyoh86.lib.autocmd.Augroup, event: kyoh86.lib.autocmd.Events, opts?: kyoh86.lib.autocmd.CreateOpts): integer
---@field clear fun(self: kyoh86.lib.autocmd.Augroup)
---@field del fun(self: kyoh86.lib.autocmd.Augroup, id: integer)
local augroup = { group = 0 }
augroup.__index = augroup

---@class kyoh86.lib.autocmd.Bufgroup: kyoh86.lib.autocmd.Augroup
---@field buffer integer
---@field hook fun(self: kyoh86.lib.autocmd.Bufgroup, event: kyoh86.lib.autocmd.Events, opts?: kyoh86.lib.autocmd.CreateOpts): integer
local bufgroup = { buffer = 0 }
bufgroup.__index = bufgroup
setmetatable(bufgroup, { __index = augroup })

---@param group integer
local function new_group(group)
  local instance = { group = group }
  setmetatable(instance, augroup)
  return instance
end

---@param group integer
---@param buffer integer
local function new_buf_group(group, buffer)
  local instance = { group = group, buffer = buffer }
  setmetatable(instance, bufgroup)
  return instance
end

--- Creates an `autocommand` event handler, defined by `callback` (Lua function or Vimscript
--- function _name_ string) or `command` (Ex command string).
---
--- Example using Lua callback:
---
--- ```lua
--- local au = require("kyoh86.lib.autocmd")
--- local g = au.group("YourGroup")
--- g:hook({'BufEnter', 'BufWinEnter'}, {
---   pattern = {'*.c', '*.h'},
---   callback = function(ev)
---     print(string.format('event fired: %s', vim.inspect(ev)))
---   end
--- })
--- ```
---
--- @see vim.api.nvim_create_autocmd
--- @see vim.api.nvim_del_autocmd
--- @param event kyoh86.lib.autocmd.Events Event(s) that will trigger the handler (`callback` or `command`).
--- @param opts? kyoh86.lib.autocmd.CreateOpts Options dict:
--- - pattern (string|array) optional: pattern(s) to match literally `autocmd-pattern`.
--- - buffer (integer) optional: buffer number for buffer-local autocommands
--- `autocmd-buflocal`. Cannot be used with {pattern}.
--- - desc (string) optional: description (for documentation and troubleshooting).
--- - callback (function|string) optional: Lua function (or Vimscript function name, if
--- string) called when the event(s) is triggered. Lua callback can return a truthy
--- value (not `false` or `nil`) to delete the autocommand, and receives one argument, a
--- table with these keys: [event-args]()
---     - id: (number) autocommand id
---     - event: (vim.api.keyset.events) name of the triggered event `autocmd-events`
---     - group: (number|nil) autocommand group id, if any
---     - file: (string) [<afile>] (not expanded to a full path)
---     - match: (string) [<amatch>] (expanded to a full path)
---     - buf: (number) [<abuf>]
---     - data: (any) arbitrary data passed from [nvim_exec_autocmds()] [event-data]()
--- - command (string) optional: Vim command to execute on event. Cannot be used with
--- {callback}
--- - once (boolean) optional: defaults to false. Run the autocommand
--- only once `autocmd-once`.
--- - nested (boolean) optional: defaults to false. Run nested
--- autocommands `autocmd-nested`.
--- @return integer # Autocommand id (number)
function augroup:hook(event, opts)
  return vim.api.nvim_create_autocmd(event, vim.tbl_extend("keep", { group = self.group }, opts or {}))
end

--- Clears all autocommands in the group.
function augroup:clear()
  vim.api.nvim_clear_autocmds({ group = self.group })
end

--- Deletes a specific autocommand by id.
---@param id integer
function augroup:del(id)
  vim.api.nvim_del_autocmd(id)
end

--- Creates a buffer-local autocommand handler.
---
--- This always sets {buffer} and clears {pattern} to avoid the mutual exclusion rule.
--- @param event kyoh86.lib.autocmd.Events Event(s) that will trigger the handler (`callback` or `command`).
--- @param opts? kyoh86.lib.autocmd.CreateOpts Options dict (pattern is ignored).
--- @return integer # Autocommand id (number)
function bufgroup:hook(event, opts)
  local merged = vim.tbl_extend("keep", { group = self.group, buffer = self.buffer }, opts or {})
  merged.pattern = nil
  return vim.api.nvim_create_autocmd(event, merged)
end

--- Create or get an autocommand group `autocmd-groups`.
---
--- To get an existing group id, do:
---
--- ```lua
--- local au = require("kyoh86.lib.autocmd")
--- local g = au.group("YourGroup", false)
--- g:hook(...
--- ```
---
--- @param name string String: The name of the group
--- @param clear? boolean optional: defaults to true. Clear existing
--- commands if the group already exists `autocmd-groups`.
--- @return kyoh86.lib.autocmd.Augroup # A handler for autocmds in the created group
function autocmd.group(name, clear)
  return new_group(vim.api.nvim_create_augroup(name, { clear = clear }))
end

--- Create or get a buffer-local autocommand group.
---
--- If {name} is omitted, it uses "kyoh86_buf_{bufnr}".
--- @param buffer integer Buffer number
--- @param name? string String: The name of the group
--- @param clear? boolean optional: defaults to true. Clear existing
--- commands if the group already exists `autocmd-groups`.
--- @return kyoh86.lib.autocmd.Bufgroup # A handler for buffer-local autocmds
function autocmd.buf_group(buffer, name, clear)
  local group_name = name or ("kyoh86_buf_%d"):format(buffer)
  return new_buf_group(vim.api.nvim_create_augroup(group_name, { clear = clear }), buffer)
end

return autocmd
