# ZSHコマンドハイライト設定
local cands=(
    '/usr/share/zsh-syntax-highlighting'
    '/usr/share/zsh/plugins/zsh-syntax-highlighting'
    '/usr/local/share/zsh-syntax-highlighting'
    '/opt/homebrew/share/zsh-syntax-highlighting'
    "$HOME/.nix-profile/share/zsh-syntax-highlighting"
)
local cand=''
for cand in $cands; do
    if [ -d "${cand}/highlighters" ]; then
        export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR="${cand}/highlighters"
        for f in $(find "${cand}/highlighters" -name "*.zsh"); do
            if [ ! -e "${f}.zwc" ] || [ "${f}" -nt "${f}.zwc" ]; then
                zcompile "${f}" >/dev/null 2>&1 || :
            fi
        done
        _source_if "${cand}/zsh-syntax-highlighting.zsh"
    fi
done
