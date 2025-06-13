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

---FPATH環境変数に、autoloadするディレクトリを追加する
---@param dir string
local function reg_fpath(dir)
  local p = vim.env.NVIM_ZSH_FPATH
  if not p or p == "" then
    p = dir
  else
    p = p .. ":" .. dir
  end
  vim.env.NVIM_ZSH_FPATH = p
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
