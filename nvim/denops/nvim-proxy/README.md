# nvim-proxy

Neovim と外部クライアント (Codex / git pre-commit) の橋渡し用プロキシ。 各
Neovim インスタンスは自分の情報を登録し、外部は固定ポートの
プロキシだけを参照する。

## 目的

- 複数 Neovim の同時起動に対応する
- MCP と pre-commit を安定した固定アドレスに集約する
- DenopsRestart によるアドレス変更を吸収する

## アーキテクチャ

```
Neovim (denops/mcp) --register--> nvim-proxy (37125)
Codex (MCP) ---------------------> nvim-proxy (/mcp) --forward--> denops/mcp
git pre-commit ------------------> nvim-proxy (/pre-commit) --> denops/pre-commit
```

### 関連コンポーネント

- `nvim/denops/nvim-proxy/main.ts`
  - 起動確認とサービス起動 (任意)
  - `NVIM_PROXY_URL` / `NVIM_PID` を環境変数として設定
- `nvim/denops/nvim-proxy/proxy.ts`
  - 固定ポートで待ち受け
  - `path` 単位で登録済みの転送先へプロキシ
- `nvim/denops/mcp/main.ts`
  - MCP サーバ本体 (ランダムポート)
  - 起動時に `/register` へ自身を登録
- `git/hooks/pre-commit`
  - `NVIM_PROXY_URL` と `NVIM_PID` を使ってプロキシへ問い合わせ
- `codex/config.toml`
  - `mcp_servers.nvim_proxy` に固定 URL を設定
  - `env_http_headers` で `X-Nvim-Pid` を送信
- `nvim/denops/pre-commit/main.ts`
  - 起動時に `/register` へ自身を登録

## 固定ポート

- プロキシ: `http://127.0.0.1:37125`
- Neovim MCP: ランダムポート (0) で起動し、登録で共有

## 登録情報

`/register` に送る payload は以下:

```json
{
  "pid": 12345,
  "path": "/mcp",
  "target_url": "http://127.0.0.1:37287/mcp"
}
```

pre-commit 側は `/pre-commit` を登録する:

```json
{
  "pid": 12345,
  "path": "/pre-commit",
  "target_url": "127.0.0.1:40001"
}
```

## プロキシのHTTPエンドポイント

- `GET /health` : 稼働確認
- `GET /routes` : 登録済みルート一覧
- `POST /register` : Neovim インスタンスの登録/更新
- `* /mcp` : MCP の透過転送
- `POST /pre-commit` : pre-commit の透過転送

## ヘルスチェック

登録されたルートに対して `GET /health` を定期実行し、失敗が続いたら削除する。 10
分間隔で 3 回失敗したら削除 (タイムアウトは 2 秒)。

## 環境変数

Neovim 側でセットされる値:

- `NVIM_PROXY_URL` : `http://127.0.0.1:37125`
- `NVIM_PID` : Neovim 本体の PID
- `NVIM_MCP_URL` : ランダムポートで起動した MCP の URL
- `PRECOMMIT_ADDRESS` : denops/pre-commit の URL (プロキシ登録用)

Codex 側は `NVIM_PID` を `X-Nvim-Pid` ヘッダとして送信する。

## ルーティング規則

- MCP: `X-Nvim-Pid` を必須とし、その PID のインスタンスに転送
- pre-commit: `X-Nvim-Pid` を必須とし、その PID のインスタンスに転送

## 設定

### Neovim

- 自動起動を切りたい場合:
  - `let g:nvim_proxy_autostart = 0`
- コマンド:
  - `:NvimProxyInstall` : サービスをインストールして起動
  - `:NvimProxyStart` : サービスの起動
  - `:NvimProxyRestart` : サービスの再起動
  - `:NvimProxyEnsure` : 起動チェック。未起動なら案内を表示
  - `:NvimProxyStatus` : サービスの状態を表示
- `:checkhealth nvim_proxy` で状態とルート一覧を確認できる

### Codex

```toml
[mcp_servers.nvim_proxy]
url = "http://127.0.0.1:37125/mcp"
env_http_headers = { "X-Nvim-Pid" = "NVIM_PID" }
```

## 動作確認

```sh
echo "NVIM_PROXY_URL=$NVIM_PROXY_URL"
echo "NVIM_PID=$NVIM_PID"
curl -sS http://127.0.0.1:37125/health
```

Codex では `nvim_current_buffer` 等を呼び出す。

## サービス運用

### Linux (systemd user)

`~/.config/systemd/user/nvim-proxy.service` を作成し、`systemctl --user`
で起動。

### macOS (launchd)

`~/Library/LaunchAgents/com.kyoh86.nvim-proxy.plist` を作成し、`launchctl`
で起動。

どちらも `:NvimProxyInstall` がテンプレートを生成し、起動まで実行する。 `deno`
のパスや `proxy.ts` の場所が変わった場合は再インストールする。

## 注意点

- DenopsRestart 後は新しい terminal で環境変数が更新される。
- `NVIM_PID` が無いと MCP は動作しない。
