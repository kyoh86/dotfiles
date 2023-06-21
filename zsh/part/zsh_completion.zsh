# 自動補完の設定
if [ ! -d "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/completions" ]; then
    mkdir -p "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/completions"
fi
fpath=("${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/completions" $fpath)

autoload -Uz compinit && compinit
