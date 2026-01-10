import * as vars from "@denops/std/variable";
import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { startProxyServer } from "./proxy.ts";

const DEFAULT_PROXY_URL = "http://127.0.0.1:37125";
let proxyServerStarted = false;

export async function main(denops: Denops): Promise<void> {
  const autostart = await vars.g.get(denops, "nvim_proxy_autostart", 1);
  if (autostart !== 0) {
    await ensureProxyServer();
  }

  const pid = await fn.getpid(denops);

  await vars.e.set(denops, "NVIM_PROXY_URL", DEFAULT_PROXY_URL);
  await vars.e.set(denops, "NVIM_PID", String(pid));
}

async function ensureProxyServer() {
  if (proxyServerStarted) {
    return;
  }
  try {
    const res = await fetch(`${DEFAULT_PROXY_URL}/health`);
    if (res.ok) {
      return;
    }
  } catch {
    // Continue to start the proxy server.
  }
  try {
    startProxyServer();
    proxyServerStarted = true;
  } catch {
    // Another instance might have started the server.
  }
}
