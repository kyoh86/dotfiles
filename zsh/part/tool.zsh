# GnuPGでPassphraseを使う際のTTYを設定
export GPG_TTY="$(tty)"

# mongoshでのファイル実行: 常に--nodbで始めるオプション
# mongorun hoge.js のように使う
alias mongorun='mongosh --nodb --quiet'
