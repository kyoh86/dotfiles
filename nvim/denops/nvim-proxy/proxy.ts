import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import * as z from "zod";

const DEFAULT_HOST = "127.0.0.1";
const DEFAULT_PORT = 37125;

type InstanceInfo = {
  pid: number;
  cwd: string;
  mcpUrl: string;
  precommitUrl: string;
  servername?: string;
  updatedAt: number;
};

const instances = new Map<number, InstanceInfo>();

export type ProxyServerOptions = {
  host?: string;
  port?: number;
};

export function startProxyServer(options: ProxyServerOptions = {}) {
  const host = options.host ?? DEFAULT_HOST;
  const port = options.port ?? DEFAULT_PORT;

  const server = createMcpServer();
  const transport = new WebStandardStreamableHTTPServerTransport({
    sessionIdGenerator: () => crypto.randomUUID(),
    enableJsonResponse: true,
  });
  server.connect(transport);

  const handler = async (req: Request) => {
    const { pathname } = new URL(req.url);
    if (pathname === "/mcp") {
      return transport.handleRequest(req);
    }
    if (pathname === "/health") {
      return json({ status: "ok" });
    }
    if (pathname === "/register" && req.method === "POST") {
      return await handleRegister(req);
    }
    if (pathname === "/pre-commit" && req.method === "POST") {
      return await handlePreCommit(req);
    }
    return new Response("Not found", { status: 404 });
  };

  return Deno.serve({ hostname: host, port, handler });
}

function createMcpServer() {
  const server = new McpServer({
    name: "nvim-proxy",
    version: "0.1.0",
  });

  registerProxyTool(server, "nvim_buffers");
  registerProxyTool(server, "nvim_current_buffer");
  registerProxyTool(server, "nvim_current_selection");
  registerProxyTool(server, "nvim_list_items");
  registerProxyTool(server, "nvim_diagnostics");

  return server;
}

function registerProxyTool(server: McpServer, toolName: string) {
  server.registerTool(
    toolName,
    {
      title: `Proxy ${toolName}`,
      description: `Proxy call to ${toolName} on the selected Neovim instance.`,
      inputSchema: z.object({}).passthrough(),
    },
    async (args, extra) => {
      const pidFromHeader = parsePid(extra.requestInfo?.headers?.["x-nvim-pid"]);
      const instance = resolveInstance(pidFromHeader);
      if (!instance) {
        return errorResult(
          "No Neovim instance selected. Ensure NVIM_PID is set.",
        );
      }
      return await callInstanceTool(instance, toolName, args);
    },
  );
}

function resolveInstance(pidFromHeader?: number) {
  if (pidFromHeader) {
    const byPid = instances.get(pidFromHeader);
    if (byPid) {
      return byPid;
    }
  }
  return undefined;
}

function parsePid(value: string | string[] | undefined) {
  if (!value) {
    return undefined;
  }
  const raw = Array.isArray(value) ? value[0] : value;
  const parsed = Number(raw);
  if (Number.isFinite(parsed) && parsed > 0) {
    return parsed;
  }
  return undefined;
}

async function callInstanceTool(
  instance: InstanceInfo,
  toolName: string,
  args: unknown,
) {
  const url = ensureHttpUrl(instance.mcpUrl);
  const request = {
    jsonrpc: "2.0",
    id: crypto.randomUUID(),
    method: "tools/call",
    params: {
      name: toolName,
      arguments: args,
    },
  };
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "accept": "application/json, text/event-stream",
      },
      body: JSON.stringify(request),
    });
    const json = await res.json();
    if (json?.result) {
      return json.result;
    }
    if (json?.error?.message) {
      return errorResult(`Proxy error: ${json.error.message}`);
    }
    return errorResult("Proxy error: unexpected response");
  } catch (error) {
    return errorResult(`Proxy error: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function handleRegister(req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return json({ error: "Invalid body" }, 400);
  }
  const record = body as Record<string, unknown>;
  const pid = Number(record.pid ?? 0);
  const cwd = String(record.cwd ?? "");
  const mcpUrl = String(record.mcp_url ?? "");
  const precommitUrl = String(record.precommit_url ?? "");
  if (!pid || !cwd || !mcpUrl) {
    return json({ error: "Missing fields" }, 400);
  }
  instances.set(pid, {
    pid,
    cwd,
    mcpUrl,
    precommitUrl,
    servername: typeof record.servername === "string" ? record.servername : undefined,
    updatedAt: Date.now(),
  });
  return json({ ok: true });
}

async function handlePreCommit(req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return new Response("invalid body", { status: 400 });
  }
  const record = body as Record<string, unknown>;
  const dir = String(record.dir ?? "");
  if (!dir) {
    return new Response("invalid dir", { status: 400 });
  }
  const pid = Number(record.pid ?? 0);
  const instance = Number.isFinite(pid) && pid > 0
    ? instances.get(pid)
    : resolveInstanceForDir(dir);
  if (!instance || !instance.precommitUrl) {
    return new Response("ok");
  }
  const url = ensureHttpUrl(instance.precommitUrl);
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ dir }),
    });
    const text = await res.text();
    return new Response(text);
  } catch (error) {
    return new Response(
      `error: ${error instanceof Error ? error.message : String(error)}`,
      { status: 500 },
    );
  }
}

function resolveInstanceForDir(dir: string) {
  const candidates = Array.from(instances.values())
    .filter((instance) => dir.startsWith(instance.cwd))
    .sort((a, b) => {
      if (a.cwd.length !== b.cwd.length) {
        return b.cwd.length - a.cwd.length;
      }
      return b.updatedAt - a.updatedAt;
    });
  return candidates[0];
}

function ensureHttpUrl(url: string) {
  if (url.startsWith("http://") || url.startsWith("https://")) {
    return url;
  }
  return `http://${url}`;
}

function errorResult(message: string) {
  return {
    content: [{ type: "text", text: message }],
    isError: true,
  };
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

if (import.meta.main) {
  startProxyServer();
}
