import * as vars from "@denops/std/variable";
import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import { registerBufferTools } from "./tools/buffers.ts";
import { registerDiagnosticsTool } from "./tools/diagnostics.ts";
import { registerListItemsTool } from "./tools/list_items.ts";
import { registerStateTools } from "./tools/state.ts";
import { logError } from "./util.ts";

const DEFAULT_PORT = 0;
const LOCAL_HOST = "127.0.0.1";
const REGISTER_RETRY_LIMIT = 5;
const REGISTER_BACKOFF_BASE_MS = 200;

export async function main(denops: Denops): Promise<void> {
  const port = await resolvePort(denops);
  const server = new McpServer({
    name: "nvim-denops",
    version: "0.1.0",
  });

  registerBufferTools(server, denops);
  registerStateTools(server, denops);
  registerListItemsTool(server, denops);
  registerDiagnosticsTool(server, denops);

  const transport = new WebStandardStreamableHTTPServerTransport({
    sessionIdGenerator: undefined,
    enableJsonResponse: true,
  });

  await server.connect(transport);

  const handler = async (req: Request) => {
    try {
      const { pathname } = new URL(req.url);
      if (pathname === "/mcp") {
        return await transport.handleRequest(req);
      }
      if (pathname === "/health") {
        return new Response(JSON.stringify({ status: "ok" }), {
          headers: { "content-type": "application/json; charset=utf-8" },
        });
      }
      return new Response("Not found", { status: 404 });
    } catch (error) {
      logError("nvim-mcp: request failed", error);
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
    console.error("Failed to start nvim MCP server:", error);
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
  console.error("Failed to register MCP server to nvim-proxy.");
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
    proxy_path: "/mcp",
    reverse_port: options.port,
    reverse_path: "/mcp",
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

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function resolvePort(denops: Denops): Promise<number> {
  const fromVar = await vars.g.get(denops, "nvim_mcp_port");
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
  const fromEnv = Number(Deno.env.get("NVIM_MCP_PORT") ?? "");
  if (Number.isFinite(fromEnv) && fromEnv >= 0 && fromEnv <= 65535) {
    return fromEnv;
  }
  return DEFAULT_PORT;
}
