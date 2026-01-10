---
name: denops-author
description: Best practices for Denops plugin implementation drawn from lambdalisue's Denops plugins. Use when Codex needs concrete patterns for buffer/local/global/env vars, key mappings, and Vimscript/TypeScript boundaries in Denops plugins based on those repos.
---

# Denops Author Practices (lambdalisue)

Use this skill to ground Denops implementation details in lambdalisue's Denops plugins only.

## Quick reference (examples-based patterns)

- Buffer vars: use `vars.b.get` and error if missing.
  Source: `denops/gin/command/blame/buffer_utils.ts`
  https://raw.githubusercontent.com/lambdalisue/vim-gin/main/denops/gin/command/blame/buffer_utils.ts
- Buffer-local mappings: `b:did_ftplugin` guard + `setlocal` + `<Plug>` indirection + `g:` flag to disable.
  Source: `ftplugin/gin-status.vim`
  https://raw.githubusercontent.com/lambdalisue/vim-gin/main/ftplugin/gin-status.vim
- g:/env vars batching: `batch.gather` + `batch.batch` to reduce RPCs.
  Source: `denops/askpass/main.ts`
  https://raw.githubusercontent.com/lambdalisue/vim-askpass/main/denops/askpass/main.ts
- g: defaults: define helper with `get(g:, name, default)` at plugin entry.
  Source: `plugin/kensaku.vim`
  https://raw.githubusercontent.com/lambdalisue/vim-kensaku/main/plugin/kensaku.vim
- Batch config read: `collect` to read `v:` and `g:` at once; coerce booleans.
  Source: `denops/guise/main.ts`
  https://raw.githubusercontent.com/lambdalisue/vim-guise/main/denops/guise/main.ts
- DenopsPluginPost hook: define commands that call `denops#notify`, then wire autocmd.
  Source: `plugin/chameleon.vim`
  https://raw.githubusercontent.com/lambdalisue/vim-chameleon/main/plugin/chameleon.vim
- Interrupt/cleanup: use `denops.interrupted` and return `Symbol.asyncDispose`.
  Source: `denops/chameleon/main.ts`
  https://raw.githubusercontent.com/lambdalisue/vim-chameleon/main/denops/chameleon/main.ts
- Collect + fn wrappers: batch multiple `fn.*` calls with `collect`.
  Source: `denops/initial/main.ts`
  https://raw.githubusercontent.com/lambdalisue/vim-initial/main/denops/initial/main.ts
- Abort signal composition: combine `denops.interrupted` with local `AbortController`.
  Source: `denops/refine/main.ts`
  https://raw.githubusercontent.com/lambdalisue/vim-refine/main/denops/refine/main.ts
- Early exit + autocmd setup: check env/args and `finish`, then `augroup` + `autocmd`.
  Source: `plugin/guise.vim`
  https://raw.githubusercontent.com/lambdalisue/vim-guise/main/plugin/guise.vim

## Workflow

1. Identify the task type (buffer vars, mappings, global/env vars, dispatcher/API boundary).
2. Open `references/denops-author-examples.md` and extract the closest matching example.
3. Follow the same structure and naming conventions; adapt to the target plugin but keep the pattern.
4. When responding, cite the example file path and explain the rationale briefly.

## Notes

- Keep Vimscript responsibilities minimal; push logic into Denops TypeScript where possible.
- Prefer `@denops/std` modules for Vim interactions instead of raw `denops.call` when an example shows that pattern.
- Use buffer-local mappings and `<Plug>` indirections as shown in the references.
