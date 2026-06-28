import * as vars from "@denops/std/variable";
import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { toolDefinitions } from "./schema.ts";
import { callTool, RpcError } from "./tools/mod.ts";
import { logError } from "./util.ts";

const DEFAULT_PORT = 0;
const LOCAL_HOST = "127.0.0.1";
const REGISTER_RETRY_LIMIT = 5;
const REGISTER_BACKOFF_BASE_MS = 200;

export async function main(denops: Denops): Promise<void> {
  const port = await resolvePort(denops);
  const handler = async (req: Request) => {
    try {
      const { pathname } = new URL(req.url);
      if (pathname === "/rpc" && req.method === "POST") {
        return await handleRpcRequest(denops, req);
      }
      if (pathname === "/tools" && req.method === "GET") {
        return json({
          tools: toolDefinitions.map(({ name, title, description }) => ({
            name,
            title,
            description,
          })),
        });
      }
      if (pathname === "/health") {
        return json({ status: "ok" });
      }
      return json({ error: "Not found" }, 404);
    } catch (error) {
      logError("nvim-rpc: request failed", error);
      throw error;
    }
  };

  try {
    const { finished } = Deno.serve({
      hostname: LOCAL_HOST,
      port,
      handler,
      onListen: async ({ port }) => {
        await registerToProxy(denops, { port });
      },
    });
    await finished;
  } catch (error) {
    console.error("Failed to start nvim RPC server:", error);
  }
}

async function handleRpcRequest(denops: Denops, req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return json({ error: "Invalid body" }, 400);
  }
  const tool = readStringField(body, "tool");
  if (!tool) {
    return json({ error: "tool is required" }, 400);
  }
  try {
    const result = await callTool(
      denops,
      tool,
      (body as Record<string, unknown>).arguments ?? {},
    );
    return json({ ok: true, result });
  } catch (error) {
    if (error instanceof RpcError) {
      return json({ error: error.message }, error.status);
    }
    logError("nvim-rpc: tool failed", error);
    return json({ error: formatError(error) }, 500);
  }
}

async function registerToProxy(
  denops: Denops,
  options: { port: number },
) {
  const pid = await fn.getpid(denops);
  for (let attempt = 0; attempt < REGISTER_RETRY_LIMIT; attempt += 1) {
    const ok = await registerOnce(denops, {
      pid,
      port: options.port,
    });
    if (ok) {
      return;
    }
    if (attempt < REGISTER_RETRY_LIMIT - 1) {
      await delay(REGISTER_BACKOFF_BASE_MS * 2 ** attempt);
    }
  }
  console.error("Failed to register RPC server to nvim-proxy.");
}

async function registerOnce(
  denops: Denops,
  options: {
    pid: number;
    port: number;
  },
) {
  const proxyUrl = await vars.e.get(denops, "NVIM_PROXY_URL", "");
  if (!proxyUrl) {
    return false;
  }
  const registerUrl = `${proxyUrl.replace(/\/+$/, "")}/register`;
  const payload = {
    pid: options.pid,
    proxy_path: "/rpc",
    reverse_port: options.port,
    reverse_path: "/rpc",
  };
  try {
    const res = await fetch(registerUrl, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(payload),
    });
    return res.ok;
  } catch {
    return false;
  }
}

function readStringField(body: object, key: string) {
  if (!(key in body)) {
    return undefined;
  }
  const value = (body as Record<string, unknown>)[key];
  return typeof value === "string" ? value : undefined;
}

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function resolvePort(denops: Denops): Promise<number> {
  const fromVar = await vars.g.get(denops, "nvim_rpc_port");
  if (typeof fromVar === "number" && Number.isFinite(fromVar)) {
    if (fromVar >= 0 && fromVar <= 65535) {
      return fromVar;
    }
  }
  if (typeof fromVar === "string") {
    const parsed = Number(fromVar);
    if (Number.isFinite(parsed) && parsed >= 0 && parsed <= 65535) {
      return parsed;
    }
  }
  const fromEnv = Number(Deno.env.get("NVIM_RPC_PORT") ?? "");
  if (Number.isFinite(fromEnv) && fromEnv >= 0 && fromEnv <= 65535) {
    return fromEnv;
  }
  return DEFAULT_PORT;
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

function formatError(error: unknown) {
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}
