---
name: denops-author
description: Best practices for Denops plugin implementation drawn from lambdalisue's Denops plugins. Use when Codex needs concrete patterns for buffer/local/global/env vars, key mappings, and Vimscript/TypeScript boundaries in Denops plugins based on those repos.
---

# Denops Author Practices (lambdalisue)

Use this skill to ground Denops implementation details in lambdalisue's Denops plugins only.

## Workflow

1. Identify the task type (buffer vars, mappings, global/env vars, dispatcher/API boundary).
2. Open `references/denops-author-examples.md` and extract the closest matching example.
3. Follow the same structure and naming conventions; adapt to the target plugin but keep the pattern.
4. When responding, cite the example file path and explain the rationale briefly.

## Notes

- Keep Vimscript responsibilities minimal; push logic into Denops TypeScript where possible.
- Prefer `@denops/std` modules for Vim interactions instead of raw `denops.call` when an example shows that pattern.
- Use buffer-local mappings and `<Plug>` indirections as shown in the references.
