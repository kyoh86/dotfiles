# Arch LinuxとWindowsのデュアルブート

久々にやったら結構めんどくさかったので

- USBメディアの用意
    - Windowsでもできる！はあんまり信用できない。Windows製USBメディアへの書き込みソフトの信頼性に疑問がある
    - fdisk/ddしか勝たん
- パーティションの用意
    - Windows側でWindowsのプライマリ縮める
    - インストール手順の中でfdisk/mkfs.xxxする羽目になるのであとはあまり気にしない
- インストール
    - vimとefibootmgrはカーネルとついでにインストールしておいたほうが良い
- ブートローダー設定
    - EFIブートスタブより凝ったことやりたくない
    - efibootmgr --create....でOK
- ネットワーク接続（忘れがちなのでメモ）
    - systemd-networkd以外使う予定なし
    - 忘れがちなので注意
        - systemd-networkdとsystemd-resolvd有効化
        - /etc/systemd/network/20-wired.networkでのDHCP=yes
