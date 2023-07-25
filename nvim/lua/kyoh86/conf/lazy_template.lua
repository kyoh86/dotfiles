---Lazy.nvim用の設定やプラグインの設定をさっと作る
local function start_edit(smods, dirname, name)
  name = string.gsub(name, ".lua", "")
  local fullpath = table.concat({ vim.fn.stdpath("config"), "lua", "kyoh86", dirname, name }, "/") .. ".lua"
  vim.cmd({ cmd = "new", mods = smods, args = { fullpath } })
end

local function start_edit_file(smods, fargs, dirname)
  if #fargs > 0 then
    start_edit(smods, dirname, fargs[1])
  else
    vim.ui.input({ prompt = "File name: " }, function(v)
      if v == nil then
        return
      end
      local name = vim.fn.trim(v)
      if name ~= "" then
        start_edit(smods, dirname, name)
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

vim.api.nvim_create_user_command("LazyConf", function(cmd)
  start_edit_file(cmd.smods, cmd.fargs, "conf")
end, { nargs = "?", force = true })
vim.api.nvim_create_user_command("LazyPlug", function(cmd)
  start_edit_file(cmd.smods, cmd.fargs, "plug")
  fill_plug_template()
end, { nargs = "?", force = true })
