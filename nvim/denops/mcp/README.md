# denops RPC server

Neovim 内の情報を取得するための内部 RPC サーバ。外部公開用の MCP は
`nvim-mcp-proxy` が担当し、この denops プラグインは MCP を実装しない。

## 役割

- Neovim のバッファや診断情報を内部 RPC として提供
- 起動時に `nvim-proxy` へ `/rpc` を登録する
- リクエスト元の Neovim 特定は `nvim-proxy` の `X-Nvim-Pid` ルーティングに任せる

## 起動

`main.ts` が `Deno.serve` でランダムポートに起動し、`nvim-proxy` に `/rpc`
として登録する。外部クライアントは直接このランダムポートを参照しない。

## 内部エンドポイント

- `GET /health` : 稼働確認
- `GET /tools` : 提供する内部 tool の一覧
- `POST /rpc` : `{ "tool": "...", "arguments": { ... } }` を実行

## 提供するツール

- `nvim_buffers`
- `nvim_current_buffer`
- `nvim_current_selection`
- `nvim_cwd`
- `nvim_list_items`
- `nvim_diagnostics`
- `nvim_reload_buffer`
- `nvim_get_buffer_content`
- `nvim_save_buffer`
- `nvim_open_file`
- `help_query`

## 関連

- `nvim/denops/nvim-proxy/README.md`
- `nvim/denops/nvim-mcp-proxy/README.md`
