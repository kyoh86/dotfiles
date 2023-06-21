# GnuPGでPassphraseを使う際のTTYを設定
if [ "$NVIM_TERMINAL" = "1" ]; then
    : # in nvim
else
    export GPG_TTY="$(tty)"
fi

# mongoshでのファイル実行: 常に--nodbで始めるオプション
# mongorun hoge.js のように使う
alias mongorun='mongosh --nodb --quiet'
