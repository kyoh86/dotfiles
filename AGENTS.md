# Repository Guidelines

## Communication Preferences

- Responses from Codex should be in Japanese unless quoting code or fixed English terms.

## Project Structure & Module Organization

- `nvim/` contains the Neovim configuration; `denops/` under it holds Deno/TypeScript sources and tests, while `lua/` stores Lua modules and plugin setup.
- `setup/` includes OS-specific bootstrap steps (`arch`, `ubuntu24`, `darwin`) and helper docs like `another_git.md`; keep new provisioning steps in this tree.
- `bin/` provides small helper scripts; `dotfiles-agent/` builds a Docker image used as a GitHub credential helper.
- Other dotfile folders (`zsh`, `wezterm`, `git`, `gh`, etc.) mirror the target configuration locations; place new configs alongside related tools to keep the layout predictable.

## Build, Test, and Development Commands

- From `nvim/`: `deno task fmt` to format TypeScript/JSONC and `deno task lint` for static analysis.
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
- Before opening a PR, run `deno task fmt`, `deno task lint`, `deno task check`, and `deno task test`, plus `stylua` if Lua changed.
- PRs should summarize scope, mention affected platforms (e.g., WSL, macOS), and note any manual steps (`setup/` scripts, new env vars). Link related issues when applicable.
