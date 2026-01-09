# lambdalisue Denops examples

## Sources

- https://github.com/lambdalisue/vim-gin
- https://github.com/lambdalisue/vim-askpass
- https://github.com/lambdalisue/vim-kensaku
- https://github.com/lambdalisue/vim-guise
- https://github.com/lambdalisue/vim-chameleon
- https://github.com/lambdalisue/vim-initial
- https://github.com/lambdalisue/vim-refine

## Buffer-local vars in Denops (TypeScript)

Source: `denops/gin/command/blame/buffer_utils.ts`
https://raw.githubusercontent.com/lambdalisue/vim-gin/main/denops/gin/command/blame/buffer_utils.ts

Pattern highlights:
- Use `vars.b.get` to read `b:` variables from Vim.
- Validate existence and throw explicit errors when missing.
- Use `fn.bufnr` / `fn.bufname` for buffer identification.

Excerpt:
```typescript
const bufnameBlame = await vars.b.get(denops, "gin_blame_file_bufname") as
  | string
  | undefined;
if (!bufnameBlame) {
  throw new Error("Cannot find associated ginblame buffer");
}
```

## Buffer-local mappings in ftplugin (Vimscript)

Source: `ftplugin/gin-status.vim`
https://raw.githubusercontent.com/lambdalisue/vim-gin/main/ftplugin/gin-status.vim

Pattern highlights:
- Guard with `b:did_ftplugin`.
- Use `setlocal` for buffer-only options.
- Define buffer-local mappings with `<Plug>` indirection.
- Allow user disable via `g:` flag.

Excerpt:
```vim
if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

if !get(g:, 'gin_status_disable_default_mappings')
  map <buffer><nowait> a <Plug>(gin-action-choice)
  nmap <buffer><nowait> ? <Plug>(gin-action-help)
endif
```

## Global/env vars and batching (Denops)

Source: `denops/askpass/main.ts`
https://raw.githubusercontent.com/lambdalisue/vim-askpass/main/denops/askpass/main.ts

Pattern highlights:
- Use `batch.gather` to read multiple `g:` vars.
- Use `batch.batch` to set multiple env vars with `vars.e.set`.

Excerpt:
```typescript
const [disableSsh, disableSudo] = await batch.gather(
  denops,
  async (denops) => {
    await vars.g.get(denops, "askpass_disable_ssh", 0);
    await vars.g.get(denops, "askpass_disable_sudo", 0);
  },
) as [number, number];

await batch.batch(denops, async (denops) => {
  await vars.e.set(denops, "ASKPASS", askpass);
  if (!disableSsh) {
    await vars.e.set(denops, "SSH_ASKPASS", askpass);
  }
});
```

## User config defaults via g: (Vimscript)

Source: `plugin/kensaku.vim`
https://raw.githubusercontent.com/lambdalisue/vim-kensaku/main/plugin/kensaku.vim

Pattern highlights:
- Use a helper to define defaults with `get(g:, name, default)`.
- Keep config at plugin entry point.

Excerpt:
```vim
function! s:define(name, default) abort
  let g:{a:name} = get(g:, a:name, a:default)
endfunction
```

## Gather Vim vars and config in one batch (Denops)

Source: `denops/guise/main.ts`
https://raw.githubusercontent.com/lambdalisue/vim-guise/main/denops/guise/main.ts

Pattern highlights:
- Use `collect` to read `v:` and `g:` variables in one round trip.
- Coerce results to booleans explicitly for config flags.

Excerpt:
```typescript
const [progpath, disableVim, disableNeovim, disableEditor] = await collect(
  denops,
  (denops) => [
    vars.v.get(denops, "progpath", ""),
    vars.g.get(denops, "guise#disable_vim", 0),
    vars.g.get(denops, "guise#disable_neovim", 0),
    vars.g.get(denops, "guise#disable_editor", 0),
  ],
);
```

## Commands + DenopsPluginPost autocmd (Vimscript)

Source: `plugin/chameleon.vim`
https://raw.githubusercontent.com/lambdalisue/vim-chameleon/main/plugin/chameleon.vim

Pattern highlights:
- Provide user commands that call `denops#notify`.
- Use `DenopsPluginPost:{name}` for startup hooks.
- Use `get(g:, ..., default)` for config defaults.

Excerpt:
```vim
command! -nargs=0 ChameleonEnable call denops#notify('chameleon', 'enable', [])
let g:chameleon_interval = get(g:, 'chameleon_interval', 30 * 60 * 1000)
autocmd User DenopsPluginPost:chameleon ChameleonEnable
```

## Interruption handling + async dispose (Denops)

Source: `denops/chameleon/main.ts`
https://raw.githubusercontent.com/lambdalisue/vim-chameleon/main/denops/chameleon/main.ts

Pattern highlights:
- Use `denops.interrupted` with `AbortSignal` to cancel work.
- Return an object with `Symbol.asyncDispose` for cleanup.

Excerpt:
```typescript
export const main: Entrypoint = (denops) => {
  let scheduler: undefined | number;
  denops.dispatcher = { /* ... */ };
  return {
    [Symbol.asyncDispose]() {
      if (scheduler) {
        clearTimeout(scheduler);
      }
      return Promise.resolve();
    },
  };
};
```

## Bulk Vim calls with collect + fn (Denops)

Source: `denops/initial/main.ts`
https://raw.githubusercontent.com/lambdalisue/vim-initial/main/denops/initial/main.ts

Pattern highlights:
- Use `collect` to fetch multiple Vim values in one RPC.
- Use `fn.*` wrappers from `@denops/std` for better typing.

Excerpt:
```typescript
const [content_, winid, wininfos, folds] = await collect(
  denops,
  (denops) => [
    fn.getline(denops, 1, "$"),
    fn.win_getid(denops),
    getwininfo(denops),
    listFolds(denops),
  ],
);
```

## Combined abort signals for long work (Denops)

Source: `denops/refine/main.ts`
https://raw.githubusercontent.com/lambdalisue/vim-refine/main/denops/refine/main.ts

Pattern highlights:
- Combine `denops.interrupted` with a local `AbortController`.
- Abort long-running work on dispose.

Excerpt:
```typescript
const controller = new AbortController();
const signal = denops.interrupted
  ? AbortSignal.any([denops.interrupted, controller.signal])
  : controller.signal;
return {
  [Symbol.asyncDispose]() {
    controller.abort();
    return Promise.resolve();
  },
};
```

## Early exit + autocmd wiring (Vimscript)

Source: `plugin/guise.vim`
https://raw.githubusercontent.com/lambdalisue/vim-guise/main/plugin/guise.vim

Pattern highlights:
- Exit early if env vars aren’t set or headless mode is detected.
- Use `augroup` + `autocmd` for setup without user-visible commands.

Excerpt:
```vim
let s:address = has('nvim') ? $GUISE_NVIM_ADDRESS : $GUISE_VIM_ADDRESS
if empty(s:address)
  finish
endif
augroup guise_plugin_internal
  autocmd!
  autocmd VimEnter * noautocmd call guise#open(s:address, argv())
augroup END
```
