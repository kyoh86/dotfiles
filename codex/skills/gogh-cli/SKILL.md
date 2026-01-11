---
name: gogh-cli
description: Use for everyday gogh CLI operations, including auth/roots/config plus overlay, script, hook, and extra workflows.
metadata:
  short-description: gogh CLI usage
---

# gogh CLI Skill

Use this skill when a user asks for gogh CLI usage or automation flows (overlay/script/hook/extra).
Keep output concise and prefer showing the exact command with minimal explanation.

## Quick start

## Typical scenarios

- Create a new repo: `gogh create <host/owner/repo>` then `gogh clone <host/owner/repo>`
- Find existing repo (local): `gogh list [--format ...] [--primary]`
- Find existing repo (remote): `gogh repos [--limit N] [--privacy ...]`
- Show repo for current dir: `gogh cwd`


- Help: `gogh help` or `gogh <command> --help`
- List local repos: `gogh list`
- Show repo for current dir: `gogh cwd`
- Clone: `gogh clone <host/owner/repo>` or full URL
- Create: `gogh create <host/owner/repo>`
- Fork: `gogh fork <owner/repo> --to <target-owner>`
- Delete: `gogh delete <host/owner/repo>`
- List remote repos: `gogh repos`

## Auth & config

- Login (device flow): `gogh auth login <host>`
- List tokens: `gogh auth list`
- Logout: `gogh auth logout <host> <owner>`
- Show config: `gogh config show`
- Set defaults: `gogh config set-default-host <host>`, `gogh config set-default-owner <host> <owner>`
- Migrate config to current format: `gogh config migrate`

## Roots (multi-root)

- List: `gogh roots list`
- Add: `gogh roots add <path> [--primary]`
- Remove: `gogh roots remove <path>`
- Set primary: `gogh roots set-primary <path>`

## Bundle (export/import)

- Dump: `gogh bundle dump [-f <file>]`
- Restore: `gogh bundle restore [-f <file>] [--dry-run]`

## Overlay

Overlays are file templates applied into repos.

- Add: `gogh overlay add --name <name> --path <rel/path> --file <src>`
- Show: `gogh overlay show <id>`
- List: `gogh overlay list`
- Update: `gogh overlay update <id> [--name ...] [--path ...] [--file ...]`
- Remove: `gogh overlay remove <id>`
- Apply: `gogh overlay apply <id> <repo>`

## Script

Scripts are Lua snippets executed inside repo directories.

- Add: `gogh script add --name <name> --file <script.lua>`
- Create interactively: `gogh script create --name <name>`
- List: `gogh script list`
- Show: `gogh script show <id>`
- Edit: `gogh script edit <id>`
- Update: `gogh script update <id> --file <script.lua>`
- Remove: `gogh script remove <id>`
- Invoke on repo: `gogh script invoke <id> <repo>`
- Invoke instantly (stdin): `gogh script invoke-instant <repo>`

Lua globals include `gogh.repo` and `gogh.hook` (when invoked by hook).

## Hook

Hooks trigger on repo events and run overlays or scripts.

Events: `post-clone`, `post-fork`, `post-create`.

- Add (overlay): `gogh hook add --name <name> --repo-pattern <glob> --event post-clone --overlay <overlay-id>`
- Add (script): `gogh hook add --name <name> --repo-pattern <glob> --event post-clone --script <script-id>`
- List: `gogh hook list`
- Show: `gogh hook show <id>`
- Update: `gogh hook update <id> [--name ...] [--repo-pattern ...] [--event ...] [--overlay <id>|--script <id>]`
- Remove: `gogh hook remove <id>`
- Invoke manually: `gogh hook invoke <id> <repo>`

## Extra

Extras bundle overlays and hooks for reuse.

- Save from repo: `gogh extra save --name <name> --repo <repo>`
- Create manually: `gogh extra create --name <name> --source <repo> [--overlay <id> ...] [--hook <id> ...]`
- List: `gogh extra list`
- Show: `gogh extra show <id>`
- Apply to repo: `gogh extra apply --name <name> [--repo <repo>]`
- Remove: `gogh extra remove <id>`

## Notes

- References can omit host/owner when defaults are configured.
- Use `gogh <command> --help` for exact flags in the installed version.
