# ref: https://blog.atusy.net/2023/02/02/zsh-as-nvim-cmdline/
if [ -n "${NVIM_SERVER_NAME}" ] ; then
  function nvim-remote-cmd() {
    local result="$(nvim --server "${NVIM_SERVER_NAME}" --headless --remote-expr "execute(v:lua.vim.base64.decode(\"$1\"))")"
    print "$result" | tail -n +2
  }

  function nvim-remote-or-not() {
    if [ "$BUFFER[1]" != ":" ] || [ "$BUFFER" = ":" ]; then
      zle accept-line
      return
    fi

    # バッファが:で始まる場合はNeovimに実行させる

    # コマンド名を取得
    local cmd_name="${BUFFER%% *}"

    # 一時的にコマンドをfunctionとして定義
    eval "${cmd_name}() { nvim-remote-cmd \"$(echo $BUFFER|base64)\" }"

    # 掃除用にプレフィックス関数の名前を保持
    TEMP_NVIM_CMD_NAME="$cmd_name"

    # 一時的に定義したコマンドのまま実行
    zle accept-line
  }

  # Enterキーでnvim-remote-or-notが発動するようにマッピング
  zle -N nvim-remote-or-not
  bindkey '^m' nvim-remote-or-not
fi

# precmdフックを設定して、一時的な関数を削除
function cleanup_temp_command() {
  if [[ -n "$TEMP_NVIM_CMD_NAME" ]]; then
    unset -f "$TEMP_NVIM_CMD_NAME"
    unset TEMP_NVIM_CMD_NAME
  fi
}

# precmd関数を追加
autoload -Uz add-zsh-hook
add-zsh-hook precmd cleanup_temp_command
