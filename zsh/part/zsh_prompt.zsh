# プロンプト設定
autoload -Uz add-zsh-hook

# nvimの中ではPromptを表示しない（nvim側で情報を表示するため）
if [ -z "${VIM_TERMINAL}" ] && [ -z "${NVIM_TERMINAL}" ] && which git-prompt >/dev/null 2>&1; then
    function _update_git_info() {
        status_string=$(git-prompt -s zsh)
        if [ $? -ne 0 ]; then
            # gitの情報を正しく取得できない場合は現在のパスを表示する
            if [[ "${PWD:h}" == "/" ]]; then
                RPROMPT="%F{blue}${PWD}%f"
            else
                RPROMPT="%F{blue}${PWD:h}%f%F{yellow}/${PWD:t}%f"
            fi
        else
            RPROMPT="${status_string}"
        fi
    }
    add-zsh-hook precmd _update_git_info
fi

PROMPT="%(?,,%F{red}[%?]%f

)%F{blue}$%f "

_prompt_executing=""
function __prompt_precmd() {
    local ret="$?"
    if test "$_prompt_executing" != "0"
    then
      _PROMPT_SAVE_PS1="$PS1"
      _PROMPT_SAVE_PS2="$PS2"
      PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
      PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
    fi
    if test "$_prompt_executing" != ""
    then
       printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
    fi
    printf "\033]133;A;cl=m;aid=%s\007" "$$"
    _prompt_executing=0
}
function __prompt_preexec() {
    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    printf "\033]133;C;\007"
    _prompt_executing=1
}
preexec_functions+=(__prompt_preexec)
precmd_functions+=(__prompt_precmd)
