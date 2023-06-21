---Lazy.nvim用の設定やプラグインの設定をさっと作る
local function start_edit(mods, dirname, name)
  name = string.gsub(name, ".lua", "")
  local fullpath = table.concat({ vim.fn.stdpath("config"), "lua", "kyoh86", dirname, name }, "/") .. ".lua"
  local cmd = "new"
  if mods == "" then
    cmd = "edit"
  end
  vim.cmd(table.concat({ mods, cmd, fullpath }, " "))
end

local function start_edit_file(mods, fargs, dirname)
  if #fargs > 0 then
    start_edit(mods, dirname, fargs[1])
  else
    vim.ui.input({ prompt = "File name: " }, function(v)
      if v == nil then
        return
      end
      local name = vim.fn.trim(v)
      if name ~= "" then
        start_edit(mods, dirname, name)
      end
    end)
  end
end

local function fill_plug_template()
  vim.fn.setline(1, {
    [[---@type LazySpec]],
    [[local spec = {]],
    [[  "",]],
    [[}]],
    [[return spec]],
  })
  vim.fn.setpos(".", { 0, 3, 4, 0 })
end

vim.api.nvim_create_user_command("LazyConf", function(event)
  start_edit_file(event.mods, event.fargs, "conf")
end, { nargs = "?", force = true })
vim.api.nvim_create_user_command("LazyConfH", function(event)
  start_edit_file("horizontal", event.fargs, "conf")
end, { nargs = "?", force = true })
vim.api.nvim_create_user_command("LazyConfV", function(event)
  start_edit_file("vertical", event.fargs, "conf")
end, { nargs = "?", force = true })
vim.api.nvim_create_user_command("LazyPlug", function(event)
  start_edit_file(event.mods, event.fargs, "plug")
  fill_plug_template()
end, { nargs = "?", force = true })
vim.api.nvim_create_user_command("LazyPlugH", function(event)
  start_edit_file("horizontal", event.fargs, "plug")
  fill_plug_template()
end, { nargs = "?", force = true })
vim.api.nvim_create_user_command("LazyPlugV", function(event)
  start_edit_file("vertical", event.fargs, "plug")
  fill_plug_template()
end, { nargs = "?", force = true })
