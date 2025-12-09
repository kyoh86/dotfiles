# Codex Ghost POC

Ghost-text style continuation powered by the Codex CLI. It paints inline virtual text and virtual lines (like Copilot) and lets you accept or dismiss.

## Requirements
- `codex` CLI reachable via `PATH`
- Normal buffers only (`buftype == ""`)

## Commands
- `:CodexGhost` — request a continuation at the cursor. Clears any existing ghost.
- `:CodexGhostAccept` — insert the current ghost at the stored position.
- `:CodexGhostDismiss` — remove the ghost without inserting.

## Keymap example
Add to your config if you want shortcuts:

```lua
local ghost = require("kyoh86.poc.codex_ghost")
vim.keymap.set("i", "<C-g>g", ghost.request, { desc = "Codex ghost" })
vim.keymap.set("i", "<C-g>a", ghost.accept, { desc = "Accept ghost" })
vim.keymap.set("i", "<C-g>d", ghost.dismiss, { desc = "Dismiss ghost" })
```

## Configuration
Edit `ghost.setup` (see `nvim/lua/kyoh86/conf/codex_ghost.lua`):
- `model`: Codex model name (optional)
- `context_before`/`context_after`: lines of context to send (default 120/60)
- `highlight`: extmark highlight group (defaults to `CodexGhost`)
- `base_highlight`: link target for `CodexGhost` if it does not exist (defaults to `Comment`)

## How it works
1) Collects surrounding text (truncated by the context settings).  
2) Builds a prompt instructing Codex to return only the continuation.  
3) Runs `codex exec --output-last-message <tmp> --color=never --skip-git-repo-check -` with the prompt via `vim.system`.  
4) Reads the last message file (preserving trailing newlines), normalizes CRLF, splits to lines (adding an empty last line if the suggestion ends with `\n`), and renders everything as `virt_lines` aligned to the cursor column (single-line stays inline).  
5) Accept inserts the same stored lines: multi-line via `nvim_buf_set_lines` at the next line; single-line via `nvim_buf_set_text` at the cursor column. Results are discarded if the buffer changed before the reply.

## Notes
- No streaming; results arrive when the command exits.
- Ghost is cleared on each new request and when accepting/dismissing.
- If Codex fails or returns empty text, the ghost is removed silently.
