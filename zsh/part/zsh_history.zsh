# コマンド履歴の設定
HISTFILE=${HOME}/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt extended_history       # 補完時にヒストリを自動的に展開
setopt hist_ignore_all_dups   # ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_space      # スペースで始まるコマンド行はヒストリリストから削除
setopt hist_reduce_blanks     # 余分な空白は詰めて記録
setopt hist_no_store          # historyコマンドは履歴に登録しない
setopt hist_verify            # ヒストリを呼び出してから実行する間に一旦編集可能

HISTORY_IGNORE="(ls|cd|rm|git|rmdir|mv|cp|export|exit)"
zshaddhistory() {
    emulate -L zsh
    [[ ${1%%$'\n'} != ${~HISTORY_IGNORE} ]]
}
