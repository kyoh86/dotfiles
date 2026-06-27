#!/usr/bin/env bash
set -euo pipefail

port="${1:-9222}"
host="${2:-127.0.0.1}"
base="http://${host}:${port}"

if curl --max-time 1 -fsSL "$base/json/version" >/dev/null 2>&1; then
  printf 'Edge DevTools is already reachable: %s/json/version\n' "$base"
  exit 0
fi

case "$host" in
  127.0.0.1|localhost) ;;
  *)
    printf 'Cannot launch Edge for non-local DevTools host: %s\n' "$host" >&2
    exit 1
    ;;
esac

powershell=""
if command -v powershell.exe >/dev/null 2>&1; then
  powershell="powershell.exe"
elif [[ -x /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe ]]; then
  powershell="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
elif command -v pwsh.exe >/dev/null 2>&1; then
  powershell="pwsh.exe"
fi

if [[ -z "$powershell" ]]; then
  printf 'powershell.exe is required to launch Windows Edge from WSL.\n' >&2
  exit 1
fi

EDGE_DEVTOOLS_PORT="$port" WSLENV="${WSLENV:+$WSLENV:}EDGE_DEVTOOLS_PORT" "$powershell" -NoProfile -ExecutionPolicy Bypass -Command '
  $ErrorActionPreference = "Stop"
  $port = [int]$env:EDGE_DEVTOOLS_PORT
  $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
  $candidates = @(
    (Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe"),
    $(if ($programFilesX86) { Join-Path $programFilesX86 "Microsoft\Edge\Application\msedge.exe" }),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Edge\Application\msedge.exe")
  ) | Where-Object { $_ -and (Test-Path $_) }
  if (-not $candidates) {
    throw "Edge executable was not found."
  }
  $edge = @($candidates)[0]
  $profile = Join-Path $env:LOCALAPPDATA "Microsoft\EdgeCodexDebug$port"
  Start-Process -FilePath $edge -ArgumentList @(
    "--remote-debugging-port=$port",
    "--user-data-dir=$profile"
  )
' >/dev/null

for _ in {1..15}; do
  if curl --max-time 1 -fsSL "$base/json/version" >/dev/null 2>&1; then
    printf 'Edge DevTools is reachable: %s/json/version\n' "$base"
    exit 0
  fi
  sleep 0.25
done

printf 'Edge was launched, but DevTools did not become reachable: %s/json/version\n' "$base" >&2
exit 1
