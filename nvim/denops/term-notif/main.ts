/**
 * :terminalの中から通知を受け取るプロキシサーバー。
 *
 * このプロキシサーバーは、terminalからの通知を受け取ると、
 * Denoのautocmdを使って、通知をVimに伝える。
 * autocmdの値は、Kyoh86TermNotifReceived:<メッセージ>という形式になる。
 *
 * シェル側ではnotify.tsを呼び出すことで、引数をこのプロキシサーバーに送信することができる。
 *
 * ref(通知送信スクリプト): ./notify.ts
 * ref(zshのコマンド終了通知): ../../../zsh/part/zsh_notify_done.zsh
 */
import type { Denops } from "https://deno.land/x/denops_std@v5.0.1/mod.ts";
import * as batch from "https://deno.land/x/denops_std@v5.0.1/batch/mod.ts";
import * as path from "https://deno.land/std@0.204.0/path/mod.ts";
import * as autocmd from "https://deno.land/x/denops_std@v5.0.1/autocmd/mod.ts";
import * as vars from "https://deno.land/x/denops_std@v5.0.1/variable/mod.ts";

export function main(denops: Denops): void {
  listen(denops).catch((e) =>
    console.error(`Unexpected error occured in the proxy server: ${e}`)
  );
}

export async function listen(denops: Denops): Promise<void> {
  const listener = Deno.listen({
    hostname: "127.0.0.1",
    port: 0,
  });
  await batch.batch(denops, async (denops) => {
    await vars.e.set(
      denops,
      "KYOH86_TERM_NOTIFY_ADDRESS",
      JSON.stringify(listener.addr),
    );
    const script = path.fromFileUrl(new URL("notify.ts", import.meta.url));
    await vars.e.set(
      denops,
      "KYOH86_TERM_NOTIFY_COMMAND",
      script,
    );
  });

  for await (const conn of listener) {
    handleConnection(denops, conn).catch((e) => console.error(e));
  }
}

async function handleConnection(
  denops: Denops,
  conn: Deno.Conn,
): Promise<void> {
  try {
    const text = conn.readable.pipeThrough(new TextDecoderStream());
    for await (
      const record of text.values()
    ) {
      await autocmd.emit(denops, "User", `Kyoh86TermNotifReceived:${record}`);
    }
  } finally {
    // conn.close();
  }
}
