# 色名による指定を有効にする
autoload -Uz colors
colors

# キーバインド設定
bindkey -e
bindkey '^d' delete-char

# その他の設定
setopt extended_glob

stty eof ''
#
# コマンドをVimで編集する
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line
