import * as vars from "@denops/std/variable";
import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { startProxyServer } from "./proxy.ts";

const DEFAULT_PROXY_URL = "http://127.0.0.1:37125";
const HEARTBEAT_INTERVAL_MS = 5000;

let proxyServerStarted = false;

export async function main(denops: Denops): Promise<void> {
  const autostart = await vars.g.get(denops, "nvim_proxy_autostart", 1);
  if (autostart !== 0) {
    await ensureProxyServer();
  }

  const pid = await fn.getpid(denops);
  const servername = await vars.v.get(denops, "servername", "");

  await vars.e.set(denops, "NVIM_PROXY_URL", DEFAULT_PROXY_URL);
  await vars.e.set(denops, "NVIM_PID", String(pid));

  const register = async () => {
    const cwd = await fn.getcwd(denops);
    const mcpUrl = String(await vars.e.get(denops, "NVIM_MCP_URL", ""));
    const precommitUrl = String(await vars.e.get(denops, "PRECOMMIT_ADDRESS", ""));
    if (!mcpUrl) {
      return;
    }
    await registerInstance({
      pid,
      cwd,
      mcp_url: mcpUrl,
      precommit_url: precommitUrl,
      servername,
    });
  };

  await register();
  const timer = setInterval(register, HEARTBEAT_INTERVAL_MS);

  if (denops.interrupted) {
    denops.interrupted.addEventListener("abort", () => clearInterval(timer));
  }
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

async function registerInstance(payload: {
  pid: number;
  cwd: string;
  mcp_url: string;
  precommit_url: string;
  servername: string;
}) {
  try {
    await fetch(`${DEFAULT_PROXY_URL}/register`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(payload),
    });
  } catch {
    // Ignore transient failures; heartbeat will retry.
  }
}
