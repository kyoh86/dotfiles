#!/usr/bin/env bash
set -euo pipefail

port="${1:-9222}"
host="${2:-127.0.0.1}"
base="http://${host}:${port}"

printf 'version=%s\n' "$base/json/version"
printf 'list=%s\n' "$base/json/list"
printf '\n-- /json/version --\n'
curl -fsSL "$base/json/version"
printf '\n\n-- /json/list --\n'
curl -fsSL "$base/json/list"
printf '\n'
