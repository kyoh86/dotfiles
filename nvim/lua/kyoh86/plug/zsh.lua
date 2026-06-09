---ZSHプラグインをここで管理しちゃう

local envar = require("kyoh86.lib.envar")

---ZSH_SOURCES環境変数に、sourceしてほしいファイルのパスを追加する
---zsh/part/source.zshで全部sourceしてる
---@param file string
local function reg_source(file)
  local p = envar.ZSH_SOURCES
  if not p or p == "" then
    p = file
  else
    p = p .. ":" .. file
  end
  envar.set_tmux("ZSH_SOURCES", p)
end

---FPATH環境変数に、autoloadするディレクトリを追加する
---@param dir string
local function reg_fpath(dir)
  local p = envar.NVIM_ZSH_FPATH
  if not p or p == "" then
    p = dir
  else
    p = p .. ":" .. dir
  end
  envar.set_tmux("NVIM_ZSH_FPATH", p)
end

---@type LazySpec
local spec = {
  {
    "olets/zsh-abbr",
    config = function(plug)
      reg_source(plug.dir .. "/zsh-abbr.zsh")
    end,
  },
  {
    "zsh-users/zsh-completions",
    config = function(plug)
      reg_fpath(plug.dir .. "/src")
    end,
  },
}
return spec
