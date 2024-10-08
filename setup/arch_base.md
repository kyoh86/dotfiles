- Windowsのインストール
    - disk partitionの用意 (EFIの拡張): 1GBくらいにしておく
        - ALT+F10 -> diskpart
- https://wiki.archlinux.jp/index.php/%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%82%AC%E3%82%A4%E3%83%89
    - mountに注意
        - mount /dev/sdXN /mnt : root ドライブ。新しく用意したパーティション
        - mount --mkdir /dev/sdXN /mnt/boot : EFI パーティションを指定する
    - pacstrapの段階でどうせ後々必要になるものをとっとと入れちゃう
        - git
        - dhcpcd
        - vim
        - sudo
    - ブートローダーはsystemd-bootで十分（インストールいらない）
        - Archのインストールが別の物理ドライブに置かれる場合は、/boot/loader/entries/arch.confだけ作っておく。EFIと同じ物理ドライブのローダーは自動で読まれる
        - UUIDはblkid -s UUID -o value /dev/sdXN として root のパーティションのUUIDを示す
        - /boot/loader.conf にtimeoutを有意な値（例: 10）で設定しておかないとブートの選択が出ないので注意
            - e.g. `TIMEOUT   10`  `=`などは不要でスペース区切りだけなので注意
- ユーザーの作成
    - `useradd -m -s /bin/bash kyoh86`
    - `passwd kyoh86`
    - sudoersにしておく
- ネットワーク設定
    - https://wiki.archlinux.jp/index.php/%E3%83%8D%E3%83%83%E3%83%88%E3%83%AF%E3%83%BC%E3%82%AF%E8%A8%AD%E5%AE%9A
    - 有線
        - systemd-networkd, systemd-resolved, dhcpcdを有効化しておく
        - DNSはIPv6が安定しないことが多いので、Public DNSを設定しておく
            - 
        - dhcpcd用にDHCPをオンにしておく
        - ネットワークインターフェース名はip aで拾っておく
        - ip link set <interface name> up でインターフェース立ち上げ
        - 下記の通りインターフェース指定でDHCPを有効化する

/etc/systemd/network/00-connected.link など
```
[Match]
Name=<インターフェイス名>

[Network]
DHCP=yes
```

## Public DNS

| 運営組織         | 優先/代替 | IPv4    | IPv6                 | ドメイン名                       |
| ---              | ---       | ---     | ---                  | ---                              |
| Google           | 優先      | 8.8.8.8 | 2001:4860:4860::8888 | google-public-dns-a.google.com   |
|                  | 代替      | 8.8.4.4 | 2001:4860:4860::8844 | google-public-dns-b.google.com   |
| Cloudflare/APNIC | 優先      | 1.1.1.1 | 2606:4700:4700::1111 | 1dot1dot1dot1.cloudflare-dns.com |
|                  | 代替      | 1.0.0.1 | 2606:4700:4700::1001 | 1dot1dot1dot1.cloudflare-dns.com |
