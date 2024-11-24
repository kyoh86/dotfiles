local group = vim.api.nvim_create_augroup("kyoh86-lib-scheme-changed", { clear = true })

--- Backgroundオプションがdark/lightで切り替わった時に呼び出される関数を登録する
--- @param f fun(name) 呼び出される関数
local function onBackgroundChanged(f, init, opt)
  --- @param value string オプション値
  local w = function(value)
    if not value or value == "" then
      return
    end
    f(value)
  end
  w(vim.opt.background)
  vim.api.nvim_create_autocmd(
    "OptionSet",
    vim.tbl_extend("force", opt or {}, {
      pattern = "background",
      group = group,
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
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function(ev)
      w(ev.match)
    end,
  })
end

return {
  onBackgroundChanged = onBackgroundChanged,
  onSchemeChanged = onSchemeChanged,
}
