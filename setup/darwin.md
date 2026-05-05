# Setup Darwin

1. Install GUI apps manually
2. Set host name
3. Run setup script
4. Setup git for another account (if you needed)

## 1. Install GUI apps manually

- [ ] Microsoft Edge
- [ ] Docker Desktop
- [ ] Raycast
- [ ] Rectangle
- [ ] Contexts
- [ ] 1Password
- [ ] Google IME
- [ ] WezTerm
- [ ] Slack
- [ ] DataGrip
- [ ] Cloudflare WARP
- [ ] Global Protect
- [ ] Falcon CrowdStrike

## 2. Set host name

1. System settings - General - Share - Local Host Name
2. Restart
3. Check host name `echo "${HOST}"`

## 3. Run setup script

```console
$ git clone --bare https://github.com/kyoh86/dotfiles $HOME/Projects/github.com/kyoh86/dotfiles
$ git -C $HOME/Projects/github.com/kyoh86/dotfiles worktree add $HOME/Projects/github.com/kyoh86/dotfiles/.worktree/main main
$ cd $HOME/Projects/github.com/kyoh86/dotfiles/.worktree/main
$ ./setup/darwin
```

## 4. Setup git for another account (if you needed)

[./another_git.md](Contribute from other user)
