# kyoh86/nvim-uitest

Tiny helper for Neovim plugin authors to set up Screen-based UI tests. It pulls Neovim's `test` tree via `curl | tar` (cached), drops a minimal init, and creates a UI test scaffold.

## Prerequisites

- Neovim 0.9+ (`--embed` support)
- `curl` and `tar` available
- Plenary installed (uses its Busted runner)

## Enable commands

Call once (e.g. from your `init.lua`):
```lua
require("kyoh86.poc.uitest").setup_commands()
```

## Commands

- `:UITestPull[!] [ref] [-cwd {path}]`  
  - Fetches `test` (helpers/testutil/screen.lua and friends) into `test/.uitest/nvimcore/test`. Defaults to `master`. `-cwd` sets working dir. `!` forces overwrite.
- `:UITestScaffold[!] {name} [-cwd {path}]`  
  - Generates `test/minimal_init.lua` and `test/ui/<name>_spec.lua`. `name` is required. `-cwd` sets working dir. `!` forces overwrite.

## What gets created

- `test/.uitest/nvimcore/test/` — Neovim test tree (includes `functional/`)
- `test/minimal_init.lua` — minimal init that wires `runtimepath`/`package.path`
- `test/ui/<name>_spec.lua` — Screen attach/expect sample

## Where to put tests

Place specs under `test/ui/*.lua`. `package.path` is wired in `test/minimal_init.lua` to include `test/.uitest/nvimcore`, so the scaffolded code runs as-is.

## Running tests (Plenary Busted runner)

```sh
NVIM_APPNAME=plugin-screen-test nvim --headless -u test/minimal_init.lua \
  -c "lua require('plenary.test_harness').test_directory('test/ui', { minimal_init = 'test/minimal_init.lua', sequential = true })" +qa
```
- `NVIM_APPNAME` is optional but keeps environments isolated
- Set `NVIM_PROG` to point to a specific Neovim if needed (used by helpers)
- To pin a ref: `:UITestPull v0.10.3` and re-run
- This pulls the full `test` tree to avoid missing deps.

## Notes

- `test/.uitest/` is meant to stay untracked; `.gitignore` is dropped automatically under `test/.uitest/`.
- Run `:UITestPull` before tests if the cache was removed.
- Default flow pulls `master`; breaking changes upstream may affect your tests. Pin a tag if you need stability.
- Scaffolding is non-destructive by default; add `!` to overwrite.
- If your plugin needs extra deps, extend `test/minimal_init.lua` with the required `runtimepath`/settings.
- Want to refresh the test tree manually?  
  `curl -L https://github.com/neovim/neovim/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 --wildcards -C test/.uitest/nvimcore "*/test"`

## Quick Screen usage

```lua
package.path = vim.fn.getcwd() .. "/test/.uitest/nvimcore/?.lua;" .. vim.fn.getcwd() .. "/test/.uitest/nvimcore/?/init.lua;" .. package.path

local helpers = require("test.functional.helpers")(after_each)
local Screen = require("test.functional.ui.screen")
local feed, clear = helpers.feed, helpers.clear

describe("basic screen check", function()
  local screen

  before_each(function()
    clear({ args = { "-u", vim.fn.getcwd() .. "/test/minimal_init.lua", "--cmd", "set shortmess+=I" } })
    screen = Screen.new(40, 8)
    screen:attach()
  end)

  it("echoes input", function()
    feed("ihello<Esc>")
    screen:expect([[
      hello                               |
      ~                                   |
      ~                                   |
      ~                                   |
      ~                                   |
      ~                                   |
      ~                                   |
                                          |
    ]])
  end)
end)
```
- For highlight checks, map IDs via `screen:set_default_attr_ids`; ignore noisy attrs with `screen:set_default_attr_ignore`.
- For async scenarios, use `screen:wait(function() ... end)` to avoid flaky expectations.
