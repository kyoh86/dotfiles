# kyoh86/nvim-uitest

Tiny helper for Neovim plugin authors to set up Screen-based UI tests. It pulls the minimal Screen deps from the Neovim repo via `curl | tar`, drops a minimal init, and creates a UI test scaffold.

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
  - Fetches the minimal Screen dependencies (helpers/testutil/screen.lua etc.) into `test/nvimcore/functional`. Defaults to `master`. `-cwd` sets working dir. `!` forces overwrite.
- `:UITestScaffold[!] {name} [-cwd {path}]`  
  - Generates `test/minimal_init.lua` and `test/ui/<name>_spec.lua`. `name` is required. `-cwd` sets working dir. `!` forces overwrite.

## What gets created

- `test/nvimcore/functional/` — Neovim Screen/Helpers (minimal set)
- `test/minimal_init.lua` — minimal init that wires `runtimepath`/`package.path`
- `test/ui/<name>_spec.lua` — Screen attach/expect sample

## Where to put tests

Place specs under `test/ui/*.lua`. `package.path` is wired in `test/minimal_init.lua` to include `test/nvimcore`, so the scaffolded code runs as-is.

## Running tests (Plenary Busted runner)

```sh
NVIM_APPNAME=plugin-screen-test nvim --headless -u test/minimal_init.lua \
  -c "lua require('plenary.test_harness').test_directory('test/ui', { minimal_init = 'test/minimal_init.lua', sequential = true })" +qa
```
- `NVIM_APPNAME` is optional but keeps environments isolated
- Set `NVIM_PROG` to point to a specific Neovim if needed (used by helpers)
- To pin a ref: `:UITestPull v0.10.3` and re-run
- This pulls a minimal set (Screen/helpers). If you need more from `test/functional`, grab the rest manually.

## Notes

- Default flow pulls `master`; breaking changes upstream may affect your tests. Pin a tag if you need stability.
- Scaffolding is non-destructive by default; add `!` to overwrite.
- If your plugin needs extra deps, extend `test/minimal_init.lua` with the required `runtimepath`/settings.
- Need the rest of `test/functional`? Manually pull it:  
  `curl -L https://github.com/neovim/neovim/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 -C test/nvimcore "*/test/functional"`

## Quick Screen usage

```lua
package.path = vim.fn.getcwd() .. "/test/nvimcore/?.lua;" .. vim.fn.getcwd() .. "/test/nvimcore/?/init.lua;" .. package.path

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
