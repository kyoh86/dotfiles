# Repository Guidelines For Claude

- Follow repository-specific instructions in [AGENTS.md](./AGENTS.md) when they exist.
- Responses should be in Japanese unless quoting code or fixed English terms.
- Never write secrets, API keys, auth tokens, SSH material, cookies, or machine-local credentials into tracked files in this repository.
- Claude local state must stay outside the repository, or in untracked `.claude/**/*.local.*` files only.
- Prefer project guidance in tracked docs such as `AGENTS.md`, `README.md`, and files under `setup/`, and keep machine-local overrides out of git.
- Shared cross-agent working context lives in `.kyoh86-context/` and must remain untracked.
- Read `.kyoh86-context/task.md` and `.kyoh86-context/handoff.md` at the start of work if they exist.
- Update `.kyoh86-context/handoff.md` and `.kyoh86-context/state.json` at the end of work when cross-agent handoff is useful.
- Treat `.kyoh86-context/` as a short-lived work buffer, not a knowledge base.
- Use caveman-style handoff writing: no preamble, no politeness, no history dump, one fact per line, preserve file paths and commands verbatim.
- Keep handoff sections fixed and short: `Goal`, `Done`, `Facts`, `Suspects`, `Next`.
- Keep each handoff section to at most 3 lines. If it grows, compress it instead of appending.

## Safe Local State

- Use user-level Claude configuration such as `~/.config/claude` for persistent local state.
- If project-local Claude settings are unavoidable, keep them in untracked files under `.claude/`, such as `.claude/settings.local.json` or `.claude/*.local.md`.
- Do not create or update tracked files for secrets, environment-specific tokens, or per-machine preferences.
