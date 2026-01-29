local au = require("kyoh86.lib.autocmd")
local group = au.group("kyoh86.lib.scheme", true)

--- Backgroundオプションがdark/lightで切り替わった時に呼び出される関数を登録する
--- @param f fun(name) 呼び出される関数
local function onBackgroundChanged(
  f,
  _ --[[init]],
  opt
)
  --- @param value string オプション値
  local w = function(value)
    if not value or value == "" then
      return
    end
    f(value)
  end
  w(vim.opt.background)
  group:hook(
    "OptionSet",
    vim.tbl_extend("force", opt or {}, {
      pattern = "background",
      callback = function()
        w(vim.v.option_new)
      end,
    })
  )
end

--- カラースキームが変更されたタイミングで呼び出される関数を登録する
--- @param f fun(name) 呼び出される関数
local function onSchemeChanged(f, init)
  --- @param name string カラースキーム名
  local w = function(name)
    if not name or name == "" then
      return
    end
    f(name)
  end
  if init then
    w(vim.g.colors_name)
  end
  group:hook("ColorScheme", {
    callback = function(ev)
      w(ev.match)
    end,
  })
end

return {
  onBackgroundChanged = onBackgroundChanged,
  onSchemeChanged = onSchemeChanged,
}
