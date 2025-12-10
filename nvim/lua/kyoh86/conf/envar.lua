--- 環境変数設定
--- ZSHとVIM両方に効かせる環境変数はここで設定する
--- ZSHだけでいい場合は.zshenvで設定すればよい

local app_name = vim.env.NVIM_APPNAME
if app_name == "" or app_name == nil then
  app_name = "nvim"
end
local config_home = vim.fn.substitute(vim.fn.stdpath("config")--[[@as string]], "/" .. app_name .. "$", "", "") -- ${xdg-CONFIG-home}/nvim
local data_home = vim.fn.substitute(vim.fn.stdpath("data")--[[@as string]], "/" .. app_name .. "$", "", "") -- ${xdg-DATA-home}/nvim
local cache_home = vim.fn.substitute(vim.fn.stdpath("cache")--[[@as string]], "/" .. app_name .. "$", "", "") -- ${xdg-CACHE-home}/nvim
local path = require("kyoh86.conf.envar.path")

vim.env.XDG_CONFIG_HOME = config_home
vim.env.XDG_DATA_HOME = data_home
vim.env.XDG_CACHE_HOME = cache_home

-- 基本環境設定:
vim.env.LANG = "ja_JP.UTF-8"
vim.env.LC_ALL = "en_US.UTF-8"
vim.env.LC_CTYPE = "en_US.UTF-8"
vim.env.COLORTERM = "xterm-256color"
vim.env.TERM = "xterm-256color"

-- Neovim server name
vim.env.NVIM_SERVER_NAME = vim.v.servername

-- 基本のPath設定:

-- dotfiles自体の在り処を環境変数として設定
local dotfiles = path.home .. "/.config"
vim.env.DOTFILES = dotfiles
vim.env.DOTS = dotfiles

-- Zsh:
vim.env.ZDOTDIR = path.home .. "/.config/zsh"

-- Groovy:
vim.env.GROOVY_HOME = "/usr/local/opt/groovy/libexec"

-- Go:
vim.env.GO111MODULE = "on"
vim.env.GOPATH = path.home .. "/go"
path.ins("/usr/local/go/bin")
path.ins(vim.env.GOPATH .. "/bin")

-- Go AWS Library
vim.env.AWS_SDK_LOAD_CONFIG = 1

-- Generator-go-project:
vim.env.GO_PROJECT_ROOT = path.home .. "/Projects"

-- Python:
-- (support sqlite3 and mysql library (used by mypy, etc...))
vim.env.LDFLAGS = "-L/usr/local/opt/zlib/lib -L/usr/local/opt/sqlite/lib"
vim.env.CPPFLAGS = "-I/usr/local/opt/zlib/include -I/usr/local/opt/sqlite/include"
local library_path = vim.env.LIBRARY_PATH
if library_path then
  library_path = library_path .. ":/usr/local/opt/openssl/lib/"
else
  library_path = "/usr/local/opt/openssl/lib/"
end
vim.env.LIBRARY_PATH = library_path

-- Node:
path.ins("./node_modules/.bin")

-- GNU commands:
path.ins("/usr/local/opt/gzip/bin")
path.ins("/usr/local/opt/openssl/bin")

-- Yarn:
path.ins(path.home .. "/.yarn/bin")

-- Perl:
path.ins(path.home .. "/perl5/bin")

-- Git:
path.ins("/usr/local/share/git-core/contrib/diff-highlight")
vim.env.GIT_SSH_COMMAND = "ssh -4"
-- Rg:
vim.env.RIPGREP_CONFIG_PATH = dotfiles .. "/ripgrep/config"

-- Gigamoji:
vim.env.GIGAMOJI_BG = ":space:"

-- GnuPG:
vim.env.GNUPGHOME = config_home .. "/gnupg"

-- Docker:
if vim.fn.has("mac") == 1 then
  vim.env.MACHINE_STORAGE_PATH = data_home .. "/docker-machine-osx"
elseif vim.fn.has("linux") == 1 then
  vim.env.MACHINE_STORAGE_PATH = data_home .. "/docker-machine-linux"
end

-- Rust:
path.ins(path.home .. "/.cargo/bin")
vim.env.CARGO_NET_GIT_FETCH_WITH_CLI = "true"

-- Snap:
path.ins("/snap/bin")

-- JAVA (using Coursier)
path.ins(path.home .. "/.local/share/coursier/bin")
vim.uv
  .new_async(vim.schedule_wrap(function()
    if vim.fn.executable("coursier") then
      vim.env.JAVA_HOME = vim.fn.trim(vim.fn.system("coursier java-home"))
    end
    path.ins(vim.env.JAVA_HOME .. "/bin")
  end))
  :send()

-- Deno:
path.ins(path.home .. "/.deno/bin")

-- Tig:
path.ins(dotfiles .. "/tig/clip")

-- browser
local glaze = require("kyoh86.lib.glaze")
glaze.get("opener", function(opener)
  vim.env.BROWSER = opener
end)

-- Homebrew:
path.ins("/opt/homebrew/bin")

-- mise
local mise_candidates = { path.home .. "/.local/bin/mise", "/opt/homebrew/bin" }
for _, c in pairs(mise_candidates) do
  if vim.fn.executable(c) == 1 then
    local mise_result = vim.system({ c, "ls", "--json", "--installed" }, { cwd = path.home, text = true }):wait()
    if mise_result.code == 0 then
      local mise_list = vim.json.decode(mise_result.stdout)
      for _, entries in pairs(mise_list) do
        for _, entry in pairs(entries) do
          if entry.active then
            path.ins(entry.install_path)
            path.ins(entry.install_path .. "/bin")
          end
        end
      end
    else
      vim.notify("Failed to get mise envar" .. mise_result.stderr, vim.log.levels.WARN)
    end
    break
  end
end

-- .local/bin
path.ins(path.home .. "/.local/bin")
path.ins(path.home .. "/.local/sbin")

-- .config/bin
path.ins(config_home .. "/bin")

path.apply()
