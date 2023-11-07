---ZSHプラグインをここで管理しちゃう

---zsh_sources環境変数に、sourceしてほしいファイルのパスを追加する
---zsh/part/source.zshで全部sourceしてる
---@param file string
local function reg_source(file)
  local p = vim.env.zsh_sources
  if not p or p == "" then
    p = file
  else
    p = p .. ":" .. file
  end
  vim.env.zsh_sources = p
end

---NOTE: autoload系はFPATHを使うとかで簡単なプラグインマネージャっぽい動きはできそう

---@type LazySpec
local spec = { {
  "olets/zsh-abbr",
  config = function(plug)
    reg_source(plug.dir .. "/zsh-abbr.zsh")
  end,
}, {
  "olets/zsh-window-title",
  config = function(plug)
    vim.env.ZSH_WINDOW_TITLE_DIRECTORY_DEPTH = 3
    reg_source(plug.dir .. "/zsh-window-title.zsh")
  end,
} }
return spec
