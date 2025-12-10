# Contribute from other user

If I want to use this repository on another git user...

## Setup

### 1. Build dotfiles-agent

```console
$ docker buildx build -t dotfiles-agent ./dotfiles-agent --build-arg MACHINE_NAME="${HOST}"
```

- `HOST` is the hostname of the machine where I want to use this repository.
- `dotfiles-agent` is a docker image that contains GitHub CLI to use as git credential helper.

### 2. Configure git

Set dotfiles local config to use dotfiles-agent as git credential helper.

```console
$ git config user.name kyoh86
$ git config user.email me@kyoh86.dev
$ git config commit.gpgsign false
$ git config advice.skippedCherryPicks false
$ git config 'url.https://kyoh86@github.com/.insteadof' 'https://github.com/'
$ git config 'url.https://kyoh86@gist.github.com/.insteadof' 'https://gist.github.com/'
```
