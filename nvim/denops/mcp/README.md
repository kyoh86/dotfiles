# denops MCP server

Neovim 内の情報を取得するための MCP サーバ。 外部からは `nvim-proxy`
経由でアクセスする。

## 役割

- Neovim のバッファや診断情報を MCP tool として提供
- 起動時に `nvim-proxy` へ `/register` で自身を登録する

## 起動

`main.ts` が `Deno.serve` で起動する。 ポートは 0 (空きポート)
で起動し、実際のリクエストはnvim-proxyのサーバーで受け付ける

## 提供するツール

- `nvim_buffers`
  - バッファ一覧
  - `dir` / `modifiedOnly` / `limit` で絞り込み
- `nvim_current_buffer`
  - カレントバッファとカーソル位置
- `nvim_current_selection`
  - 現在の視覚選択 (テキスト・範囲)
- `nvim_list_items`
  - quickfix / loclist の内容
- `nvim_diagnostics`
  - LSP diagnostics
- `help_query`
  - helpタグ検索と該当ファイルのコンテキスト取得

## 主要な環境変数

- `NVIM_PROXY_URL` : `http://127.0.0.1:37125` (登録先)

## 関連

- `nvim/denops/nvim-proxy/README.md`
- `nvim/denops/dirty-bufs/README.md`
