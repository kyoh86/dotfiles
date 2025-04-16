#!/bin/bash

# Login to GitHub CLI
login_github_cli() {
  if gh auth status --hostname github.com; then
    return;
  fi
  gh auth login --web --git-protocol https --hostname github.com --skip-ssh-key --scopes admin:public_key,admin:ssh_signing_key
  GITHUB_NAME="$(gh api /user --jq '.login')"
  if [ "${GITHUB_NAME}" != "kyoh86" ]; then
    echo "GitHub user name is not kyoh86. Please check your GitHub account."
    exit 1
  fi
}
login_github_cli

# Generate a new SSH key for github.com
generate_ssh_key() {
  SSH_KEY_PATH="${HOME}/.ssh/github_ed25519"
  if [ -f "${SSH_KEY_PATH}" ]; then
    return;
  fi
  mkdir -p "${HOME}/.ssh"
  ssh-keygen -t ed25519 -C "${GITHUB_EMAIL}" -f "${SSH_KEY_PATH}"
}
generate_ssh_key

# Upload SSH auth key to GitHub
upload_ssh_key() {
  SSH_KEY_PATH="${HOME}/.ssh/github_ed25519.pub"
  if [ ! -f "${SSH_KEY_PATH}" ]; then
    return 1;
  fi

  gh ssh-key add --title "git-auth/dotfiles-agent/${MACHINE_NAME}" --type "authentication" "${SSH_KEY_PATH}"
}
upload_ssh_key
