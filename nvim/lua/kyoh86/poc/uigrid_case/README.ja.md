# uigrid case

`uigrid_snapshot.lua` をケースディレクトリとして実行するための最小構成です。

## 使い方

```sh
nvim --headless -u NONE -i NONE -l nvim/lua/kyoh86/poc/uigrid_snapshot.lua \
  --case nvim/lua/kyoh86/poc/uigrid_case
```

## 構成

- `case.json` ケース定義
- `case.schema.json` JSON Schema
- `scenario.lua` 操作シナリオ

## case.json の主なキー

- `scenario` シナリオのパス（デフォルト: `scenario.lua`）
- `width` / `height` UIサイズ
- `data_home` / `config_home` XDGパス
- `out_dir` 出力先ディレクトリ
- `outputs` 出力ファイル名や無効化設定

`outputs` は `"none"` または `false` で無効化できます。
