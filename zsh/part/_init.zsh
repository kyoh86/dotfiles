#!/bin/sh

_source_part zsh_history
_source_part zsh_prompt
_source_part zsh_completion
_source_part zsh_highlight
_source_part zsh_misc

_source_part zsh_source

_source_part gpg
_source_part env
_source_part ls
_source_part tool
_source_part ssm
_source_part zmv
_source_part sdkman
_source_part pnpm

_source_part util/put_zsh_history
_source_part util/update_deno_dependencies
_source_part util/revive_job
_source_part util/nvim_env
_source_part util/show_github_issue
_source_part util/switch_awsenv
_source_part util/switch_git_branch
_source_part util/update
