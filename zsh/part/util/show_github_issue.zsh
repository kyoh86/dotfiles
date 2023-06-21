# Issueを開く
function show_github_issue() {
    local selected
    selected=$(
        gh issue list --state open --limit 100 |
            fzf --preview 'gh issue view -p {1}' |
            cut -f1
    )
    if [ -z "${selected}" ]; then
        return
    fi
    BUFFER="gh issue view $selected"
    zle accept-line
    # redisplay the command line
    zle -R -c
}
zle -N show_github_issue
bindkey '^xgi' show_github_issue
bindkey '^xg^i' show_github_issue
bindkey '^x^gi' show_github_issue
bindkey '^x^g^i' show_github_issue
