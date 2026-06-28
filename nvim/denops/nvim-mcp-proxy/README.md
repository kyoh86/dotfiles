# nvim-mcp-proxy

Codex などの MCP client から見る固定エンドポイント。MCP はここで終端し、 Neovim
への実処理は `nvim-proxy` 経由で各 Neovim の `/rpc` に転送する。

## 役割

- 固定ポート `37126` で MCP Streamable HTTP を受ける
- `nvim_instances` tool で `/rpc` を持つ Neovim PID だけを返す
- すべての Neovim tool は `tmux_session` を必須スコープとして受け取る
- `tmux_session` から `NVIM_PID` を解決し、`X-Nvim-Pid` ヘッダに変換する
- Neovim 側に MCP 実装を持たせない

## 起動

通常は `:NvimProxyInstall` が `nvim-proxy` と一緒にサービスを作成する。
手動起動する場合:

```sh
deno run -A --no-lock nvim/denops/nvim-mcp-proxy/proxy.ts
```

## エンドポイント

- `GET /health` : 稼働確認
- `POST /mcp` : MCP endpoint

## Codex 設定

```toml
[mcp_servers.nvim_mcp_proxy]
url = "http://127.0.0.1:37126/mcp"
```

`NVIM_PID` は MCP initialize 時には使わない。各 tool call では `tmux_session`
を必須で渡す。`nvim-mcp-proxy` は
`tmux show-environment -t <tmux_session> NVIM_PID` を都度読み、その PID
に転送する。
