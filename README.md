# dotfiles

## installation

1. setup git
1. clone dotfiles
1. call setup

### 1. setup git

1. Generate a new SSH key
    - `mkdir -p ~/.ssh`
    - ssh-keygen
        - `github_email=xxxx`
        - `ssh-keygen -t ed25519 -C "${github_email}" -f "${HOME}/.ssh/github_ed25519"`
    - `echo 'Include ~/.config/ssh/*.conf' >> ~/.ssh/config`
    - seealso: https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
1. Add a new SSH key to GitHub
    - https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account
1. Import GPG public & secret key
    - (see password manager)
    - Set path for gpg: `export GNUPGHOME=$HOME/.config/gnupg`
    - Import public key: `gpg --import xxxxxxxx.pub`
    - Import secret key: `gpg --import xxxxxxxx`
    - See key-id for git/host.conf: `gpg --list-keys --keyid-format LONG`
1. Set user name & gpg key
    - Write `~/.config/git/host.conf` like below

```
[user]
	name = kyoh86
	email = xxx@example.com
	signingkey = XXXXXXXXXXXXXXXX

[github]
	user = kyoh86
```

### 2. clone dotfiles

```console
$ git clone https://github.com/kyoh86/dotfiles ~/Projects/github.com/kyoh86/dotfiles
$ ln -s "$HOME/Projects/github.com/kyoh86/dotfiles" "$HOME/.config"
```

### 3. call setup

Ubuntu:

NOTE: Update Ubuntu before setup: https://zenn.dev/ryuu/articles/upgrade-ubuntu2204-wsl

```console
$ ~/.config/setup/ubuntu24
```

### 4. Link to hosts

```console
$ ln -s /mnt/c/Users/xxxxx /home/kyoh86/Host
```

### 4. if I want to use this repository on another git user

1. Set dotfiles local config to send patch on email to myself

```console
$ git config user.name kyoh86
$ git config user.email me@kyoh86.dev
$ git config commit.gpgsign false
$ git config advice.skippedCherryPicks false
$ git config sendEmail.smtpEncryption tls
$ git config sendEmail.smtpServer smtp.gmail.com
$ git config sendEmail.smtpServerPort 587
$ git config sendEmail.from me@kyoh86.dev
$ git config sendEmail.to me@kyoh86.dev
```

and set secret to enable send email by my private account

2. prepare app password for google from: https://myaccount.google.com/apppasswords

3. set them in config

```console
$ git config sendEmail.smtpUser <my private email>
$ git config sendEmail.smtpPass <generated app password>
```

4. when I want to commit my change on another git user

  1. make a commit and send it to myself

```console
$ git add .
$ git commit -m 'hoge'
$ git send-email HEAD~
```

  2. download email (Open Gmail.com -> Open the mail -> Download)

  3. eat it (like below)

```console
$ git am ~/Host/Downloads/*.patch
```

## my Ergodox layout

https://configure.ergodox-ez.com/ergodox-ez/layouts/MZajL/latest/0

:memo: if you want to change layout, login and edit it.
