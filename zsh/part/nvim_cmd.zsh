# ref: https://blog.atusy.net/2023/02/02/zsh-as-nvim-cmdline/
if [ -n "${NVIM_SERVER_NAME}" ] ; then
  function nvim-remote-or-accept-line() {
    # バッファが:で始まる場合はNeovimに実行させ結果を表示する
    if [ "$BUFFER[1]" = ":" ]; then
      # コマンドをNeovimに実行させ、出力を受けとる
      local RES="$(nvim --server ${NVIM_SERVER_NAME} --headless --remote-expr "execute(v:lua.vim.base64.decode(\"$(echo "$BUFFER" | base64)\"))")"

      # 出力を表示する
      printf "$RES"

      # <C-C>っぽいことして現在のZshのバッファを終了する
      zle send-break
      return
    fi

    # Neovimに送らない時は普通に処理する
    zle accept-line
  }

  # Enterキーでnvim-remote-or-accept-lineが発動するようにマッピング
  zle -N nvim-remote-or-accept-line
  bindkey '^m' nvim-remote-or-accept-line
fi
