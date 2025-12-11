# kyoh86/nvim-uitest

Neovim プラグイン開発で Screen テスト用の資材をそろえるための小ツールです。`curl | tar` で本体リポジトリの `test` と busted とその依存（Plenary/Penlight/lua_cliargs/mediator_lua/luassert/say）をキャッシュ取得し、最小 init と UI テストの雛形を生成します。

## 前提

- `nvim` 0.9 以降（`--embed` 対応）
- `curl` と `tar` が使える環境

## コマンドを有効化

どこかで一度呼び出すだけで OK（`init.lua` など）。
```lua
require("kyoh86.poc.uitest").setup_commands()
```

## 提供コマンド

- `:UITestPull[!] [ref] [-cwd {path}]`  
  - `test/.uitest/nvimcore/test` に `test`（helpers/testutil/screen.lua など）を展開し、`test/.uitest/` に Plenary と busted の依存（Penlight/lua_cliargs/mediator_lua/luassert/say）を配置します。`ref` 省略時は `master`。`-cwd` で作業ディレクトリを指定、`!` で既存を強制上書き。
- `:UITestScaffold[!] {name} [-cwd {path}]`  
  - `test/minimal_init.lua` と `test/ui/<name>_spec.lua`、`test/ui/run.lua` を生成します。`name` は必須。`-cwd` で作業ディレクトリを指定、`!` で既存を強制上書き。

## 生成されるもの

- `:UITestPull`  
    - `test/.uitest/nvimcore/test/` … Neovim 本体の `test` ツリー（`functional/` を含む）
    - `test/.uitest/plenary/` … Plenary（plenary.nvim の Lua ユーティリティ）
    - `test/.uitest/busted/` … busted 本体
    - `test/.uitest/luassert/` … luassert（テストヘルパーで利用）
    - `test/.uitest/say/` … say（luassert の依存）
    - `test/.uitest/penlight/` … Penlight（busted の依存）
    - `test/.uitest/cliargs/` … lua_cliargs（busted の依存）
    - `test/.uitest/mediator/` … mediator_lua（busted の依存）
- `:UITestScaffold`  
    - `test/minimal_init.lua` … runtimepath と package.path を通すだけの最小 init
    - `test/ui/<name>_spec.lua` … Screen attach/expect の雛形
    - `test/ui/run.lua` … `test/ui` に対して busted を呼ぶ簡易ランナー

## テストファイルの置き場所

`test/ui/*.lua` を対象に busted を使って実行します。`package.path` は `test/minimal_init.lua` 内で `test/.uitest/nvimcore`、`test/.uitest/plenary`、busted、luassert、say、および busted の依存に通すので、雛形のまま書けば動きます。

## 実行例（busted ランナー）

```sh
nvim --headless -u test/minimal_init.lua -c "luafile test/ui/run.lua" +qa
```

- `NVIM_APPNAME` は任意（環境を汚さない/環境に影響されないため推奨）。無指定なら文字列 `nvim-uitest-{現在時刻}` を使います。
- `NVIM_PROG` を変えたい場合は環境変数でパスを渡せます（helpers が参照）。無指定なら現在の `nvim` を使います。
- `ref` を固定したい場合は `:UITestPull v0.10.3` などで取得し直す

## 注意

- `test/.uitest/` は生成物なので VCS から除外する前提（`test/.uitest/` 配下に `.gitignore` を自動配置します）。
- キャッシュを消した場合はテスト実行前に `:UITestPull` を実行してください。
- master を取る運用なので、本体の破壊的変更でテストが壊れる可能性があります。安定させたいときはタグを明示して取得してください。
- 雛形は既存があれば上書きしません。再生成したいときはコマンドに `!` を付けてください。
- プラグインが外部依存を読む場合は、`test/minimal_init.lua` で必要最低限の設定や runtimepath を追加してください。
- ネイティブ依存はスタブを同梱しています: `.uitest/penlight/lua/lfs.lua`、`.uitest/busted/system.lua`、`.uitest/busted/term.lua` が自動生成されるので luarocks ビルドは不要です。
- テストツリーを手動で更新したいとき:
  `curl -L https://github.com/neovim/neovim/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 --wildcards -C test/.uitest/nvimcore "*/test/*"`
  `curl -L https://github.com/nvim-lua/plenary.nvim/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 -C test/.uitest/plenary`
  `curl -L https://github.com/Olivine-Labs/busted/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 -C test/.uitest/busted "busted-master/busted" "busted-master/busted.lua"`
  `curl -L https://github.com/lunarmodules/luassert/archive/refs/heads/master.tar.gz | tar xz --strip-components=2 -C test/.uitest/luassert "luassert-master/src"`
  `curl -L https://github.com/Olivine-Labs/say/archive/refs/heads/master.tar.gz | tar xz --strip-components=2 -C test/.uitest/say "say-master/src"`
  `curl -L https://github.com/lunarmodules/Penlight/archive/refs/heads/master.tar.gz | tar xz --strip-components=1 -C test/.uitest/penlight "Penlight-master/lua"`
  `curl -L https://github.com/amireh/lua_cliargs/archive/refs/heads/master.tar.gz | tar xz --strip-components=2 -C test/.uitest/cliargs "lua_cliargs-master/src"`
  `curl -L https://github.com/Olivine-Labs/mediator_lua/archive/refs/heads/master.tar.gz | tar xz --strip-components=2 -C test/.uitest/mediator "mediator_lua-master/src"`

## Screen のざっくり使い方

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

- 属性を検証する場合は `screen:set_default_attr_ids` を使う。不要な装飾は `screen:set_default_attr_ignore` で無視できる。
- 非同期で揺れる場合は `screen:wait(function() ... end)` を併用する。
