#!/usr/bin/env -S deno run --no-check --allow-env=KYOH86_ZSH_NOTIFY_ADDRESS --allow-net=127.0.0.1

/**
 * Zshの中からNeovimに通知を送る。
 *
 * Neovim側はDenopsで受信用のプロキシサーバーを起動している。
 *
 * ref(プロキシサーバー): ./main.ts
 * ref(zshのコマンド終了通知): ../../../zsh/part/zsh_notify_done.zsh
 */
const addr = JSON.parse(Deno.env.get("KYOH86_ZSH_NOTIFY_ADDRESS") ?? "null");
if (!addr) {
  throw new Error("KYOH86_ZSH_NOTIFY_ADDRESS environment variable is required");
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
