# AWS環境切り替え
function switch_awsenv() {
    local selected
    selected=$(
        cat ~/.aws/credentials |
            perl -ne'print $1."\n" if(/^\[(?!default\])([^\]]+)\]/)' |
            fzf
    )
    if [ -z "${selected}" ]; then
        return
    fi
    BUFFER="export AWS_DEFAULT_PROFILE=${selected}"
    zle accept-line
    # redisplay the command line
    zle -R -c
}
zle -N switch_awsenv
bindkey '^xva' switch_awsenv
bindkey '^xv^a' switch_awsenv
bindkey '^x^va' switch_awsenv
bindkey '^x^v^a' switch_awsenv
