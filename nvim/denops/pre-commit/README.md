# denops pre-commit

Git の pre-commit から呼び出されるチェック用サーバ。
未保存バッファの有無を確認し、コミット続行可否を返す。

## 役割

- `git/hooks/pre-commit` からの HTTP リクエストを受ける
- 指定ディレクトリ配下の未保存バッファを列挙
- Neovim 内で確認ダイアログを出し、継続可否を返す

## 返却値

- `ok` : 継続
- `skip` : キャンセル

## 起動

`main.ts` が `Deno.serve` で起動する。
ランダムポートで起動し、`PRECOMMIT_ADDRESS` に `host:port` を保存する。

## 関連

- `git/hooks/pre-commit`
- `nvim/denops/nvim-proxy/README.md`
- `nvim/denops/mcp/README.md`
