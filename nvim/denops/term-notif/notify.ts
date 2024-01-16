#!/usr/bin/env -S deno run --no-check --allow-env=KYOH86_TERM_NOTIFY_ADDRESS --allow-net=127.0.0.1

/**
 * :terminalの中からNeovimに通知を送る。
 * notify.ts <メッセージ> のように実行する。
 *
 * Neovim側はDenopsで受信用のプロキシサーバーを起動している。
 * プロキシサーバーはこのスクリプトのありかをKYOH86_TERM_NOTIFY_COMMAND環境変数に設定するので、
 * ${KYOH86_TERM_NOTIFY_COMMAND} <メッセージ> のように呼び出せる。
 *
 * ref(プロキシサーバー): ./main.ts
 * ref(zshのコマンド終了通知): ../../../zsh/part/zsh_notify_done.zsh
 */
const addr = JSON.parse(Deno.env.get("KYOH86_TERM_NOTIFY_ADDRESS") ?? "null");
if (!addr) {
  throw new Error(
    "KYOH86_TERM_NOTIFY_ADDRESS environment variable is required",
  );
}

const message = Deno.args[0];
if (!message) {
  throw new Error("No message is specified to the editor");
}

const encoder = new TextEncoder();
const conn = await Deno.connect(addr);
await conn.write(encoder.encode(message));
await conn.closeWrite();
conn.close();
