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
4) Reads the last message file (preserving trailing newlines), and renders it as extmarks (single-line → inline after the cursor column; multi-line → block `virt_lines` shown after the cursor line, aligned to its display column).  
5) Accept inserts using stored insert coordinates: single-line at the cursor column; multi-line padded to the cursor column, including any trailing empty line from the suggestion so the inserted block matches the displayed ghost. Results are discarded if the buffer changed before the reply.

## Notes
- No streaming; results arrive when the command exits.
- Ghost is cleared on each new request and when accepting/dismissing.
- If Codex fails or returns empty text, the ghost is removed silently.
