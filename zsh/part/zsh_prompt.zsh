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
