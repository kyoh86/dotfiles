# Repository Guidelines

## Communication Preferences

- Responses from Codex should be in Japanese unless quoting code or fixed English terms.

## Setup

```bash
# Clone and setup dotfiles
git clone --branch ubuntu https://github.com/kyoh86/dotfiles $HOME/Projects/github.com/kyoh86/dotfiles
cd $HOME/Projects/github.com/kyoh86/dotfiles

# Arch Linux (WSL)
./setup/arch

# Ubuntu 24 (WSL)
./setup/ubuntu24
```

## Project Structure & Module Organization

- `nvim/` contains the Neovim configuration; `denops/` under it holds Deno/TypeScript sources and tests, while `lua/` stores Lua modules and plugin setup.
- `setup/` includes OS-specific bootstrap steps (`arch`, `ubuntu24`, `darwin`) and helper docs like `another_git.md`; keep new provisioning steps in this tree.
- `bin/` provides small helper scripts; `dotfiles-agent/` builds a Docker image used as a GitHub credential helper.
- Other dotfile folders (`zsh`, `wezterm`, `git`, `gh`, etc.) mirror the target configuration locations; place new configs alongside related tools to keep the layout predictable.

## Architecture

### Zsh Configuration

- Entry point: `zsh/.zshrc` → loads `zsh/part/_init.zsh`
- Configuration files are auto-compiled to `zsh/.zshrc.zwc` for performance
- Loading order in `zsh/part/_init.zsh`: history → prompt → completion → highlight → misc → notify → title → source → various tool configurations

### Neovim Configuration Architecture

Neovim uses a modular Lua architecture:

1. **Entry point**: `nvim/init.lua` loads `kyoh86.root.preload` and `kyoh86.root.plugin`

2. **Preload** (`nvim/lua/kyoh86/root/preload.lua`):
   - Provides `kyoh86.ensure(spec, callback, failed)` for safe module loading with callbacks
   - Provides `kyoh86.lazydir(name)` to get lazy.nvim plugin paths
   - Auto-loads all `lua/kyoh86/conf/*.lua` via `vim.cmd.runtime()`

3. **Plugin system** (`nvim/lua/kyoh86/root/plugin.lua`):
   - Uses lazy.nvim for plugin management
   - Imports plugins from `lua/kyoh86/plug/*.lua`

4. **Configuration structure**:
   - `lua/kyoh86/conf/*.lua`: Core Neovim settings (auto-loaded by preload)
   - `lua/kyoh86/plug/*.lua`: Plugin specifications for lazy.nvim
   - `lua/kyoh86/lib/`: Utility libraries
   - `lua/kyoh86/poc/`: Proof-of-concept/experimental features

### Denops Workspace

`nvim/denops/` is a Deno workspace with multiple packages:
- DDU filters: `@ddu-filters/*`
- DDU columns: `@ddu-columns/*`
- DDU kinds: `@ddu-kinds/*`
- DDU sources: `@ddu-sources/*`
- Standalone packages: `dirty-bufs`, `mcp`, `nvim-proxy`, `tomlvsnip`

### Mise Configuration

- Configuration: `mise/config.toml`
- Installs LSP servers, tools, and language runtimes
- Hooks generate shell completions for various tools

### CI/CD

GitHub Actions workflows in `.github/workflows/`:
- `deno-test.yml`: Runs on push/PR affecting denops files
- `deno-update.yml`: Daily scheduled dependency updates (creates PR)

## Build, Test, and Development Commands

- From `nvim/`: `deno fmt` to format TypeScript/JSONC and `deno lint` for static analysis.
- `deno task check` type-checks denops sources; `deno task test` runs denops tests (requires Vim/Neovim binaries available in `PATH`).
- Lua code: `stylua --config stylua/stylua.toml nvim/**/*.lua` to format Neovim Lua files.

## Coding Style & Naming Conventions

- TypeScript follows Deno defaults: 2-space indentation, ES modules, `_test.ts` suffix for tests, and import specifiers without file extensions when possible.
- Lua uses 2-space indentation (see `stylua/stylua.toml`); keep configuration tables narrow and group plugin settings per file.
- File and directory names stay lowercase with hyphens or underscores; match existing patterns (`denops/<feature>/...`, `lua/<namespace>/...`).

## Testing Guidelines

- Tests live under `nvim/denops/**/*_test.ts`; add new coverage next to the feature code.
- Use `deno task test` locally before pushing; ensure both Vim and Neovim are available or set `DENOPS_TEST_*` env vars to point to binaries as the CI workflow does.
- Prefer small, isolated tests that mock editor interactions; avoid relying on machine-specific state.

## Commit & Pull Request Guidelines

- Commit messages are short and imperative (e.g., `update plugins`, `fix denops env`); group related changes together.
- Before opening a PR, run `deno fmt`, `deno lint`, `deno check`, and `deno task test`, plus `stylua` if Lua changed.
- PRs should summarize scope, mention affected platforms (e.g., WSL, macOS), and note any manual steps (`setup/` scripts, new env vars). Link related issues when applicable.
