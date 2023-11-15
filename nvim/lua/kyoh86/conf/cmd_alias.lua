--- Commandにエイリアスを設定するやつ。
--- require("kyoh86.conf.cmd_alias").set("hoge", "Hoge")とかすると、:hogeみたいに使える（正しいコマンド名に置換される）
return {
  set = function(alias, entity)
    vim.keymap.set({ "!a" }, alias, function()
      if vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == alias then
        return entity
      else
        return alias
      end
    end, { expr = true })
  end,
}
