import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import * as z from "zod";
import { toolDefinitions } from "../mcp/schema.ts";

const DEFAULT_HOST = "127.0.0.1";
const DEFAULT_PORT = 37126;
const DEFAULT_NVIM_PROXY_URL = "http://127.0.0.1:37125";
const MCP_SESSION_HEADER = "mcp-session-id";

type RouteRecord = {
  pid: number;
  routes: Record<string, string>;
};

export type NvimMcpProxyOptions = {
  host?: string;
  port?: number;
  nvimProxyUrl?: string;
};

export function startNvimMcpProxy(options: NvimMcpProxyOptions = {}) {
  const host = options.host ?? DEFAULT_HOST;
  const port = options.port ?? resolvePort();
  const nvimProxyUrl = (options.nvimProxyUrl ?? resolveNvimProxyUrl())
    .replace(/\/+$/, "");
  const transports = new Map<
    string,
    WebStandardStreamableHTTPServerTransport
  >();

  const createTransport = async () => {
    const transport = new WebStandardStreamableHTTPServerTransport({
      sessionIdGenerator: () => crypto.randomUUID(),
      enableJsonResponse: true,
      onsessioninitialized: (sessionId: string) => {
        transports.set(sessionId, transport);
      },
      onsessionclosed: (sessionId: string) => {
        transports.delete(sessionId);
      },
    });
    transport.onclose = () => {
      if (transport.sessionId) {
        transports.delete(transport.sessionId);
      }
    };

    const server = createServer(nvimProxyUrl);
    await server.connect(transport);
    return transport;
  };

  const handleMcpRequest = async (req: Request) => {
    const sessionId = req.headers.get(MCP_SESSION_HEADER);
    const transport = sessionId ? transports.get(sessionId) : undefined;
    if (sessionId && !transport) {
      return jsonRpcError(-32001, "Session not found", null, 404);
    }
    return await (transport ?? await createTransport()).handleRequest(req);
  };

  const handler = async (req: Request) => {
    const { pathname } = new URL(req.url);
    if (pathname === "/mcp") {
      return await handleMcpRequest(req);
    }
    if (pathname === "/health") {
      return json({ status: "ok" });
    }
    return json({ error: "Not found" }, 404);
  };

  return Deno.serve({ hostname: host, port, handler });
}

function createServer(nvimProxyUrl: string) {
  const server = new McpServer({
    name: "nvim-mcp-proxy",
    version: "0.1.0",
  });

  server.registerTool(
    "nvim_instances",
    {
      title: "List Neovim instances",
      description:
        "List Neovim instances registered in nvim-proxy for the given tmux_session.",
      inputSchema: z.object({
        tmux_session: z.string().min(1),
      }).strict(),
      outputSchema: z.object({
        instances: z.array(z.object({
          pid: z.number().int(),
          hasRpc: z.boolean(),
          current: z.boolean().optional(),
          routes: z.record(z.string(), z.string()),
        })),
      }),
    },
    async ({ tmux_session }: { tmux_session?: string }) => {
      const instances = await listInstances(nvimProxyUrl, tmux_session);
      const payload = { instances };
      return toolResult(payload);
    },
  );

  for (const definition of toolDefinitions) {
    server.registerTool(
      definition.name,
      {
        title: definition.title,
        description:
          `${definition.description} Resolves the target Neovim from the given tmux_session.`,
        inputSchema: definition.inputSchema.extend({
          tmux_session: z.string().min(1),
        }),
        outputSchema: definition.outputSchema,
      },
      async (args: Record<string, unknown>) => {
        const { tmux_session, ...toolArgs } = args as Record<
          string,
          unknown
        >;
        const session = readRequiredString(tmux_session, "tmux_session");
        const pid = await resolveTmuxNvimPid(session);
        const payload = await callNvimRpc(
          nvimProxyUrl,
          pid,
          definition.name,
          toolArgs,
        );
        return toolResult(payload);
      },
    );
  }

  return server;
}

async function listInstances(nvimProxyUrl: string, tmuxSession?: string) {
  const session = readRequiredString(tmuxSession, "tmux_session");
  const res = await fetch(`${nvimProxyUrl}/routes`);
  if (!res.ok) {
    throw new Error(`nvim-proxy routes failed: HTTP ${res.status}`);
  }
  const routes = await res.json() as RouteRecord[];
  const currentPid = await resolveTmuxNvimPid(session).catch(() => undefined);
  return routes
    .filter((record) => Boolean(record.routes["/rpc"]))
    .map((record) => ({
      pid: record.pid,
      hasRpc: true,
      current: currentPid === record.pid ? true : undefined,
      routes: record.routes,
    }));
}

async function resolveTmuxNvimPid(tmuxSession: string | undefined) {
  const session = readRequiredString(tmuxSession, "tmux_session");
  const raw = await readTmuxEnvironment("NVIM_PID", session);
  const pid = Number(raw);
  if (Number.isInteger(pid) && pid > 0) {
    return pid;
  }
  throw new Error(
    `tmux session ${session} has no NVIM_PID`,
  );
}

async function readTmuxEnvironment(name: string, tmuxSession: string) {
  const result = await runTmux(["show-environment", "-t", tmuxSession, name]);
  if (!result) {
    return undefined;
  }
  const text = new TextDecoder().decode(result.stdout).trim();
  const prefix = `${name}=`;
  return text.startsWith(prefix) ? text.slice(prefix.length) : undefined;
}

function readRequiredString(value: unknown, name: string) {
  if (typeof value === "string" && value !== "") {
    return value;
  }
  throw new Error(`${name} is required`);
}

async function runTmux(args: string[]) {
  for (const command of tmuxCommandCandidates()) {
    try {
      const result = await new Deno.Command(command, {
        args,
        stdout: "piped",
        stderr: "null",
      }).output();
      if (result.success) {
        return result;
      }
    } catch {
      // try next candidate
    }
  }
  return undefined;
}

function tmuxCommandCandidates() {
  const candidates = ["tmux"];
  const home = Deno.env.get("HOME");
  if (home) {
    candidates.push(`${home}/.local/bin/tmux`);
  }
  candidates.push("/usr/bin/tmux", "/bin/tmux");
  return Array.from(new Set(candidates));
}

async function callNvimRpc(
  nvimProxyUrl: string,
  pid: number,
  tool: string,
  args: Record<string, unknown>,
) {
  if (!Number.isInteger(pid) || pid <= 0) {
    throw new Error("resolved Neovim PID must be a positive integer");
  }
  const res = await fetch(`${nvimProxyUrl}/rpc`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-nvim-pid": String(pid),
    },
    body: JSON.stringify({ tool, arguments: args }),
  });
  const body = await res.json().catch(() => null) as
    | { ok?: boolean; result?: unknown; error?: string }
    | null;
  if (!res.ok) {
    throw new Error(body?.error ?? `nvim RPC failed: HTTP ${res.status}`);
  }
  if (!body?.ok) {
    throw new Error(body?.error ?? "nvim RPC failed");
  }
  return body.result;
}

function resolvePort() {
  const value = Number(Deno.env.get("NVIM_MCP_PROXY_PORT") ?? "");
  if (Number.isInteger(value) && value > 0 && value <= 65535) {
    return value;
  }
  return DEFAULT_PORT;
}

function resolveNvimProxyUrl() {
  return Deno.env.get("NVIM_PROXY_URL") ?? DEFAULT_NVIM_PROXY_URL;
}

function toolResult(payload: unknown) {
  return {
    content: [{
      type: "text" as const,
      text: JSON.stringify(payload, null, 2),
    }],
    structuredContent: payload as Record<string, unknown>,
  };
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

function jsonRpcError(
  code: number,
  message: string,
  id: string | number | null,
  status: number,
) {
  return new Response(
    JSON.stringify({
      jsonrpc: "2.0",
      error: { code, message },
      id,
    }),
    {
      status,
      headers: { "content-type": "application/json; charset=utf-8" },
    },
  );
}

if (import.meta.main) {
  startNvimMcpProxy();
}
