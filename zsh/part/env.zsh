# ZSHとVIM両方に効かせる環境変数はここで設定する
# nvimだけでいい場合は nvim/lua/kyoh86/conf/envar.lua に設定すれば良い

# zmodload zsh/zprof && zprof # プロファイリングをしたいときは、コメントを外す

# UID/GID
export UID
export GID

# XDG Base Directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_STAGE_HOME="${XDG_STAGE_HOME:-${HOME}/.local/state}"
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-${HOME}/.cache}

# Zsh
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

# 基本環境設定:
export LANG="ja_JP.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export COLORTERM="truecolor"
export TERM="xterm-256color"

# 基本のPath設定:

# Groovy:
export GROOVY_HOME="/usr/local/opt/groovy/libexec"

# Go:
export GOPATH="${HOME}/go"
export PATH="/usr/local/go/bin:${GOPATH}/bin:${PATH}"

# Go AWS Library
export AWS_SDK_LOAD_CONFIG=1

# Generator-go-project:
export GO_PROJECT_ROOT="${HOME}/Projects"

# Python:
# (support sqlite3 and mysql library (used by mypy, etc...))
export LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/sqlite/lib"
export CPPFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/sqlite/include"
if [ -z "${LIBRARY_PATH}" ] ; then
    export LIBRARY_PATH="/usr/local/opt/openssl/lib/"
else
    export LIBRARY_PATH="${LIBRARY_PATH}:/usr/local/opt/openssl/lib/"
fi

# zlib
export PKG_CONFIG_PATH="/usr/local/opt/zlib/lib/pkgconfig"

# Node:
export PATH="./node_modules/.bin:${PATH}"

# GNU commands:
export PATH="/usr/local/opt/gzip/bin:${PATH}"
export PATH="/usr/local/opt/openssl/bin:${PATH}"

# Yarn:
export PATH="${HOME}/.yarn/bin:${PATH}"

# Perl:
export PATH="${HOME}/perl5/bin:${PATH}"

# Git:
export PATH="/usr/local/share/git-core/contrib/diff-highlight:${PATH}"
export GIT_SSH_COMMAND="ssh -4"

# Rg:
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"

# Gigamoji:
export GIGAMOJI_BG=":space:"

# GnuPG:
export GNUPGHOME="${XDG_CONFIG_HOME}/gnupg"

# Docker:
export MACHINE_STORAGE_PATH="${XDG_DATA_HOME}/docker-machine"

# Rust:
export PATH="${HOME}/.cargo/bin:${PATH}"
export CARGO_NET_GIT_FETCH_WITH_CLI="true"

# Snap:
export PATH="/snap/bin:${PATH}"

# JAVA
export PATH="${HOME}/.local/share/coursier/bin:${PATH}"

# Deno:
export PATH="${HOME}/.deno/bin:${PATH}"

# Tig:
export PATH="${XDG_CONFIG_HOME}/tig/clip:${PATH}"

# Codex
export CODEX_HOME="${XDG_CONFIG_HOME}/codex"

# Homebrew:
export PATH="/opt/homebrew/bin:${PATH}"

# NOTE: Claude code はやたらとここに秘密情報を書き込みたがるので、Dotfiles下に置くことをやめた
# export CLAUDE_CONFIG_DIR="${XDG_CONFIG_HOME}/claude"

# .local/bin
export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${HOME}/.local/sbin:${PATH}"

# .config/bin
export PATH="${XDG_CONFIG_HOME}/bin:${PATH}"

# mise
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(command direnv hook zsh)"
fi

# Lua
if command -v luarocks >/dev/null 2>&1; then
    eval "$(luarocks --lua-version=5.1 path)"
fi

# Cargo (Rust)
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# SDKMAN
[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"
