alias ls="gls --color=auto"
[ -x /usr/local/opt/findutils/bin/gfind ] && alias find=/usr/local/opt/findutils/bin/gfind
[ -x /opt/homebrew/bin/gfind ] && alias find=/opt/homebrew/bin/gfind
[ -x /usr/local/opt/findutils/bin/gxargs ] && alias xargs=/usr/local/opt/findutils/bin/gxargs
[ -x /opt/homebrew/bin/gxargs ] && alias xargs=/opt/homebrew/bin/gxargs
[ -x /usr/local/bin/ggrep ] && alias grep="/usr/local/bin/ggrep --color=auto"
[ -x /opt/homebrew/bin/ggrep ] && alias grep="/opt/homebrew/bin/ggrep --color=auto"

# LaunchCtlジョブ選択 {{{
function insert-launchctl() {
    local selected
    selected=$(
        launchctl list | tail -n +2 | awk '{print $3}' |
            fzf
    )
    if [ -z "${selected}" ]; then
        return
    fi
    LBUFFER+="$selected"
    CURSOR=$#LBUFFER
    # redisplay the command line
    zle -R -c
}
zle -N insert-launchctl
bindkey '^xl' insert-launchctl
bindkey '^x^l' insert-launchctl
# }}}

# Homebrew pyenv 衝突の回避 {{{
# Homebrew が Python を管理対象にしろ、とAlert出してくるので
# Homebrew には pyenv 配下の Python の存在を隠す
function brew() {
    env PATH="${PATH/${HOME}\/\.pyenv\/shims:/}" command brew "$@"
}
zle -N brew
# }}}
