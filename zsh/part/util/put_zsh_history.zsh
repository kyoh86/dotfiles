# コマンド履歴検索
function put-history() {
    local selected
    selected=$(
        history -n 1 | grep -v '.\{200,\}' | awk '!a[$0]++' |
            fzf --no-sort --query="$LBUFFER"
    )
    if [ -z "${selected}" ]; then
        return
    fi
    BUFFER="$selected"
    CURSOR=$#BUFFER
    # redisplay the command line
    zle -R -c
}
zle -N put-history
bindkey '^xi' put-history
bindkey '^x^i' put-history
