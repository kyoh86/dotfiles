# 自動補完の設定
cache_completions="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/completions"
if [ ! -d "${cache_completions}" ]; then
    mkdir -p "${cache_completions}"
fi
config_completions="${XDG_CONFIG_HOME:-${HOME}/.config}/zsh/completions"
if [ ! -d "${config_completions}" ]; then
    mkdir -p "${config_completions}"
fi
fpath=("${cache_completions}" "${config_completions}" ${(@s/:/)NVIM_ZSH_FPATH} $fpath)

autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
