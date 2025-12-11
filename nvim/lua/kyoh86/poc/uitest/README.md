# kyoh86/nvim-uitest

Tiny helper for Neovim plugin authors to set up Screen-based UI tests. It pulls Neovim's `test` tree plus busted and its deps (Plenary/Penlight/lua_cliargs/mediator_lua/luassert/say) via `curl | tar` (cached), drops a minimal init, and creates a UI test scaffold.

## Prerequisites

- Neovim 0.9+ (`--embed` support)
- `curl` and `tar` available

## Enable commands

Call once (e.g. from your `init.lua`):
```lua
require("kyoh86.poc.uitest").setup_commands()
```

## Commands

- `:UITestPull[!] [ref] [-cwd {path}]`  
  - Fetches `test` (helpers/testutil/screen.lua and friends) into `test/.uitest/nvimcore/test` and bundles the busted stack (Plenary/Penlight/lua_cliargs/mediator_lua/luassert/say) into `test/.uitest/`. Defaults to `master`. `-cwd` sets working dir. `!` forces overwrite.
- `:UITestScaffold[!] {name} [-cwd {path}]`  
  - Generates `test/minimal_init.lua` and `test/ui/<name>_spec.lua`. `name` is required. `-cwd` sets working dir. `!` forces overwrite.

## What gets created

- `:UITestPull`  
    - `test/.uitest/nvimcore/test/` — Neovim test tree (includes `functional/`)
    - `test/.uitest/plenary/` — Plenary (plenary.nvim Lua helpers)
    - `test/.uitest/busted/` — busted (test runner)
    - `test/.uitest/luassert/` — luassert (assertions used by test helpers)
    - `test/.uitest/say/` — say (luassert dependency)
    - `test/.uitest/penlight/` — Penlight (busted dependency)
    - `test/.uitest/cliargs/` — lua_cliargs (busted dependency)
    - `test/.uitest/mediator/` — mediator_lua (busted dependency)
- `:UITestScaffold`  
    - `test/minimal_init.lua` — minimal init that wires `runtimepath`/`package.path`
    - `test/ui/<name>_spec.lua` — Screen attach/expect sample
    - `test/ui/run.lua` — convenience runner to invoke busted on `test/ui`

## Where to put tests

Place specs under `test/ui/*.lua`. `package.path` is wired in `test/minimal_init.lua` to include `test/.uitest/nvimcore`, `test/.uitest/plenary`, busted, luassert, say, and busted dependencies so the scaffolded code runs as-is.

## Running tests (busted runner)

```sh
nvim --headless -u test/minimal_init.lua -c "luafile test/ui/run.lua" +qa
```
- `NVIM_APPNAME` is optional but keeps environments isolated
- Set `NVIM_PROG` to point to a specific Neovim if needed (used by helpers); otherwise the current `nvim` binary is used.
- To pin a ref: `:UITestPull v0.10.3` and re-run
- This pulls the full `test` tree to avoid missing deps.

## Notes

- `test/.uitest/` is meant to stay untracked; `.gitignore` is dropped automatically under `test/.uitest/`.
- Run `:UITestPull` before tests if the cache was removed.
- Default flow pulls `master`; breaking changes upstream may affect your tests. Pin a tag if you need stability.
- Scaffolding is non-destructive by default; add `!` to overwrite.
- If your plugin needs extra deps, extend `test/minimal_init.lua` with the required `runtimepath`/settings.
- Native deps are shimmed: `.uitest/penlight/lua/lfs.lua`, `.uitest/busted/system.lua`, `.uitest/busted/term.lua` are generated to avoid luarocks builds.
- Want to refresh the test tree manually?  
  `curl -L https://github.com/neovim/neovim/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 --wildcards -C test/.uitest/nvimcore "*/test/*"`
  `curl -L https://github.com/nvim-lua/plenary.nvim/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 -C test/.uitest/plenary`
  `curl -L https://github.com/Olivine-Labs/busted/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 -C test/.uitest/busted "busted-master/busted" "busted-master/busted.lua"`
  `curl -L https://github.com/lunarmodules/luassert/archive/refs/heads/master.tar.gz | tar xz --strip-components=2 -C test/.uitest/luassert "luassert-master/src"`
  `curl -L https://github.com/Olivine-Labs/say/archive/refs/heads/master.tar.gz | tar xz --strip-components=2 -C test/.uitest/say "say-master/src"`
  `curl -L https://github.com/lunarmodules/Penlight/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 -C test/.uitest/penlight "Penlight-master/lua"`
  `curl -L https://github.com/amireh/lua_cliargs/archive/refs/heads/master.tar.gz | tar xz --strip-components=2 -C test/.uitest/cliargs "lua_cliargs-master/src"`
  `curl -L https://github.com/Olivine-Labs/mediator_lua/archive/refs/heads/master.tar.gz | tar xz --strip-components=2 -C test/.uitest/mediator "mediator_lua-master/src"`

## Quick Screen usage

```lua
package.path = vim.fn.getcwd() .. "/test/.uitest/nvimcore/?.lua;" .. vim.fn.getcwd() .. "/test/.uitest/nvimcore/?/init.lua;" .. vim.fn.getcwd() .. "/test/.uitest/busted/?.lua;" .. vim.fn.getcwd() .. "/test/.uitest/busted/?/init.lua;" .. vim.fn.getcwd() .. "/test/.uitest/luassert/?.lua;" .. vim.fn.getcwd() .. "/test/.uitest/luassert/?/init.lua;" .. vim.fn.getcwd() .. "/test/.uitest/say/?.lua;" .. vim.fn.getcwd() .. "/test/.uitest/say/?/init.lua;" .. vim.fn.getcwd() .. "/test/.uitest/penlight/lua/?.lua;" .. vim.fn.getcwd() .. "/test/.uitest/penlight/lua/?/init.lua;" .. vim.fn.getcwd() .. "/test/.uitest/cliargs/?.lua;" .. vim.fn.getcwd() .. "/test/.uitest/cliargs/?/init.lua;" .. vim.fn.getcwd() .. "/test/.uitest/mediator/?.lua;" .. vim.fn.getcwd() .. "/test/.uitest/mediator/?/init.lua;" .. vim.fn.getcwd() .. "/test/.uitest/plenary/lua/?.lua;" .. vim.fn.getcwd() .. "/test/.uitest/plenary/lua/?/init.lua;" .. package.path

local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local feed, clear = n.feed, n.clear

describe("basic screen check", function()
  local screen

  before_each(function()
    pcall(function()
      if n.get_session() then
        n.stop()
      end
    end)
    clear()
    screen = Screen.new(40, 8)
  end)

  after_each(function()
    if screen then
      screen:detach()
    end
    if n.get_session() then
      n.stop()
    end
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
