# kyoh86/nvim-uitest

Neovim プラグイン開発で Screen テスト用の資材をそろえるための小ツールです。`curl | tar` で本体リポジトリの `test/functional` を取り込み、最小 init と UI テストの雛形を生成します。

## 前提

- `nvim` 0.9 以降（`--embed` 対応）
- `curl` と `tar` が使える環境
- Plenary を導入済み（Busted ランナーを利用）

## コマンドを有効化

どこかで一度呼び出すだけで OK（`init.lua` など）。
```lua
require("kyoh86.poc.uitest").setup_commands()
```

## 提供コマンド

- `:UITestPull[!] [ref] [-cwd {path}]`  
  - `test/nvimcore/functional` に必要最小限の Screen 周辺（helpers/testutil/screen.lua など）を展開します。`ref` 省略時は `master`。`-cwd` で作業ディレクトリを指定、`!` で既存を強制上書き。
- `:UITestScaffold[!] {name} [-cwd {path}]`  
  - `test/minimal_init.lua` と `test/ui/<name>_spec.lua` を生成します。`name` は必須。`-cwd` で作業ディレクトリを指定、`!` で既存を強制上書き。

## 生成されるもの

- `test/nvimcore/functional/` … Neovim 本体の Screen/Helpers など
- `test/minimal_init.lua` … runtimepath と package.path を通すだけの最小 init
- `test/ui/<name>_spec.lua` … Screen attach/expect の雛形

## テストファイルの置き場所

`test/ui/*.lua` を対象に Plenary の Busted ランナーで実行します。`package.path` は `test/minimal_init.lua` 内で `test/nvimcore` を通すので、雛形のまま書けば動きます。

## 実行例（Plenary Busted ランナー）

```sh
NVIM_APPNAME=plugin-screen-test nvim --headless -u test/minimal_init.lua \
  -c "lua require('plenary.test_harness').test_directory('test/ui', { minimal_init = 'test/minimal_init.lua', sequential = true })" +qa
```
- `NVIM_APPNAME` は任意（環境を汚さない/環境に影響されないため推奨）
- `NVIM_PROG` を変えたい場合は環境変数でパスを渡せます（helpers が参照）
- `ref` を固定したい場合は `:UITestPull v0.10.3` などで取得し直す
- 軽量化したいときは `:UITestPull -minimal`（Screen/Helpers 周辺のみ）。不足が出る場合は `-full` で全量取得。

## 注意

- master を取る運用なので、本体の破壊的変更でテストが壊れる可能性があります。安定させたいときはタグを明示して取得してください。
- 雛形は既存があれば上書きしません。再生成したいときはコマンドに `!` を付けてください。
- プラグインが外部依存を読む場合は、`test/minimal_init.lua` で必要最低限の設定や runtimepath を追加してください。

## Screen のざっくり使い方

```lua
package.path = vim.fn.getcwd() .. "/test/nvimcore/?.lua;" .. vim.fn.getcwd() .. "/test/nvimcore/?/init.lua;" .. package.path

local helpers = require("helpers")(after_each)
local Screen = require("ui.screen")
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

- 属性を検証する場合は `screen:set_default_attr_ids` を使う。不要な装飾は `screen:set_default_attr_ignore` で無視できる。
- 非同期で揺れる場合は `screen:wait(function() ... end)` を併用する。
