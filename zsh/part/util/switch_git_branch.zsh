# ブランチ切り替え
function switch_git_branch() {
    local selected
    selected=$(
        git-branches --color !current |
            fzf -0 -n 2..3 |
            awk '{print $2}'
    )
    if [ -z "${selected}" ]; then
        return
    fi
    BUFFER="git switch $selected"
    zle accept-line
    # redisplay the command line
    zle -R -c
}
zle -N switch_git_branch
bindkey '^xgb' switch_git_branch
bindkey '^xg^b' switch_git_branch
bindkey '^x^gb' switch_git_branch
bindkey '^x^g^b' switch_git_branch
