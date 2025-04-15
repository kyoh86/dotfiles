# Contribute from other user

If I want to use this repository on another git user...

## Setup

### 1. Configure git

Set dotfiles local config to send patch on email to myself

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

### 2. Prepare App Password for Google

Prepare app password for google from: https://myaccount.google.com/apppasswords

### 3. Set Email password for git

Set a password I got in `2.` to config

```console
$ git config sendEmail.smtpUser <my private email>
$ git config sendEmail.smtpPass <generated app password>
```

## How to commit

1. Make a commit and send it to myself

```console
$ git add .
$ git commit -m 'hoge'
$ git send-email HEAD~
```

2. Download email (Open Gmail.com -> Open the mail -> Download)

3. Apply it (like below)

```console
$ git am ~/Host/Downloads/*.patch
```
