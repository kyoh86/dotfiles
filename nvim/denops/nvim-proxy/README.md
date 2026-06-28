# nvim-proxy

Neovim と外部クライアントの橋渡し用 HTTP プロキシ。各 Neovim
インスタンスは自分の内部エンドポイントを登録し、外部は固定ポートの
プロキシだけを参照する。

## 目的

- 複数 Neovim の同時起動に対応する
- DenopsRestart によるランダムポート変更を吸収する
- `X-Nvim-Pid` で明示された Neovim にだけ転送する

## アーキテクチャ

```text
Neovim (denops/mcp RPC) ----register /rpc----> nvim-proxy (37125)
nvim-mcp-proxy (MCP 37126) --X-Nvim-Pid-----> nvim-proxy (/rpc) --> denops/mcp RPC
git pre-commit ------------X-Nvim-Pid-------> nvim-proxy (/dirty-bufs) --> denops/dirty-bufs
zsh -----------------------X-Nvim-Pid-------> nvim-proxy (/env) --> denops/nvim-proxy
tmux copy-mode ------------X-Nvim-Pid-------> nvim-proxy (/setreg,/getreg,/open)
```

`nvim-proxy` は MCP を実装しない。MCP は `nvim-mcp-proxy` が担当し、Neovim
側は内部 `/rpc` だけを提供する。

## 関連コンポーネント

- `nvim/denops/nvim-proxy/main.ts`
  - `nvim-proxy` と `nvim-mcp-proxy` のサービス起動/インストール
  - `NVIM_PROXY_URL` / `NVIM_PID` を Neovim と tmux 環境に設定
  - `/env` `/notify` `/setreg` `/getreg` `/open` `/scratch` `/focus-edge` を登録
- `nvim/denops/nvim-proxy/proxy.ts`
  - 固定ポート `37125` で待ち受け
  - `X-Nvim-Pid` と path で登録済み転送先へプロキシ
- `nvim/denops/mcp/main.ts`
  - Neovim 内部 RPC サーバ
  - 起動時に `/rpc` を登録
- `nvim/denops/nvim-mcp-proxy/proxy.ts`
  - 固定ポート `37126` の MCP サーバ
  - tool call の `nvim_pid` を `X-Nvim-Pid` に変換
- `nvim/denops/dirty-bufs/main.ts`
  - 起動時に `/dirty-bufs` を登録

## 固定ポート

- `nvim-proxy`: `http://127.0.0.1:37125`
- `nvim-mcp-proxy`: `http://127.0.0.1:37126`
- Neovim 内部 RPC: ランダムポートで起動し、`/rpc` として登録

## 登録 payload

```json
{
  "pid": 12345,
  "proxy_path": "/rpc",
  "reverse_port": 37287,
  "reverse_path": "/rpc"
}
```

## HTTP エンドポイント

- `GET /health` : 稼働確認
- `GET /routes` : 登録済みルート一覧
- `POST /register` : Neovim インスタンスの登録/更新
- `POST /rpc` : Neovim 内部 RPC への透過転送
- `POST /dirty-bufs` : dirty-bufs への透過転送
- `GET/POST /env` : Neovim 内の環境変数を JSON で返す
- `POST /notify` : Neovim 内の `User` autocmd を発火する
- `POST /setreg` : Neovim の register へ文字列を書き込む
- `POST /getreg` : Neovim の register から文字列を読む
- `POST /open` : Neovim 内の file/URL opener で対象文字列を開く
- `POST /scratch` : scratch buffer を開く
- `POST /focus-edge` : tmux から Neovim pane へ入った方向に応じて端 window
  を選ぶ

`/routes` `/health` `/register` 以外の転送エンドポイントは `X-Nvim-Pid`
を必須とする。暗黙の current Neovim fallback は持たない。

## ヘルスチェック

登録されたルートに対して `GET /health` を定期実行し、失敗が続いたら削除する。10
分間隔で 3 回失敗したら削除する。転送時に対象ルートが死んでいた場合も、その場で
該当ルートを削除する。

## 永続化

`nvim-proxy` は登録ルートを `routes.json` に保存し、再起動時に復元する。

- Linux: `~/.local/state/nvim-proxy/routes.json` (or `XDG_STATE_HOME`)
- macOS: `~/.local/state/nvim-proxy/routes.json`

## 設定

### Neovim

- 自動起動を切りたい場合:
  - `let g:nvim_proxy_autostart = 0`
- コマンド:
  - `:NvimProxyInstall` : `nvim-proxy` と `nvim-mcp-proxy`
    をサービス登録して起動
  - `:NvimProxyStart` : サービスの起動
  - `:NvimProxyRestart` : サービスの再起動
  - `:NvimProxyEnsure` : 起動チェック。未起動なら案内を表示
  - `:NvimProxyStatus` : サービスの状態を表示
- `:checkhealth nvim_proxy` で状態とルート一覧を確認できる

### Codex

```toml
[mcp_servers.nvim_mcp_proxy]
url = "http://127.0.0.1:37126/mcp"
```

`NVIM_PID` は Codex の MCP initialize には使わない。`nvim-mcp-proxy` の各 Neovim
tool に `nvim_pid` を渡す。

## 動作確認

```sh
curl -sS http://127.0.0.1:37125/health
curl -sS http://127.0.0.1:37126/health
curl -sS http://127.0.0.1:37125/routes
```

Codex ではまず `nvim_instances` を呼び、返ってきた PID を各 tool の `nvim_pid`
に指定する。
