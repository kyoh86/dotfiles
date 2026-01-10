import * as vars from "@denops/std/variable";
import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import * as z from "zod";

const DEFAULT_PORT = 37123;
const DEFAULT_HOST = "127.0.0.1";

type BufferInfo = {
  name: string;
  bufnr: number;
  modified: boolean;
  buftype: string;
  listed: boolean;
  loaded: boolean;
};

export async function main(denops: Denops): Promise<void> {
  const port = await resolvePort(denops);
  const host = DEFAULT_HOST;

  const server = new McpServer({
    name: "nvim-denops",
    version: "0.1.0",
  });

  server.registerTool(
    "nvim_buffers",
    {
      title: "List Neovim buffers",
      description: "Return buffers from the active Neovim instance.",
      inputSchema: z.object({
        dir: z.string().optional(),
        modifiedOnly: z.boolean().optional(),
        limit: z.number().int().positive().optional(),
      }).strict(),
      outputSchema: z.object({
        total: z.number().int(),
        buffers: z.array(z.object({
          name: z.string(),
          bufnr: z.number().int(),
          modified: z.boolean(),
          buftype: z.string(),
          listed: z.boolean(),
          loaded: z.boolean(),
        })),
      }),
    },
    async ({ dir, modifiedOnly, limit }) => {
      const buffers = await listBuffers(denops, { dir, modifiedOnly, limit });
      const payload = { total: buffers.length, buffers };
      return {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        structuredContent: payload,
      };
    },
  );

  server.registerTool(
    "nvim_current_buffer",
    {
      title: "Get current buffer",
      description: "Return the current buffer and cursor position.",
      inputSchema: z.object({}).strict(),
      outputSchema: z.object({
        name: z.string(),
        bufnr: z.number().int(),
        modified: z.boolean(),
        cursor: z.object({
          line: z.number().int(),
          col: z.number().int(),
        }),
        cwd: z.string(),
      }),
    },
    async () => {
      const current = await getCurrentBuffer(denops);
      return {
        content: [{ type: "text", text: JSON.stringify(current, null, 2) }],
        structuredContent: current,
      };
    },
  );

  const transport = new WebStandardStreamableHTTPServerTransport({
    sessionIdGenerator: undefined,
    enableJsonResponse: true,
    enableDnsRebindingProtection: true,
    allowedHosts: [
      host,
      "localhost",
      `${host}:${port}`,
      `localhost:${port}`,
    ],
  });

  await server.connect(transport);

  const handler = (req: Request) => {
    const { pathname } = new URL(req.url);
    if (pathname === "/mcp") {
      return transport.handleRequest(req);
    }
    if (pathname === "/health") {
      return new Response(JSON.stringify({ status: "ok" }), {
        headers: { "content-type": "application/json; charset=utf-8" },
      });
    }
    return new Response("Not found", { status: 404 });
  };

  try {
    const { finished } = Deno.serve({
      hostname: host,
      port,
      handler,
      onListen: async ({ port }) => {
        await vars.e.set(denops, "NVIM_MCP_URL", `http://${host}:${port}/mcp`);
      },
    });
    await finished;
  } catch (error) {
    console.error("Failed to start nvim MCP server:", error);
  }
}

async function resolvePort(denops: Denops): Promise<number> {
  const fromVar = await vars.g.get(denops, "nvim_mcp_port");
  if (typeof fromVar === "number" && Number.isFinite(fromVar)) {
    if (fromVar > 0 && fromVar <= 65535) {
      return fromVar;
    }
  }
  if (typeof fromVar === "string") {
    const parsed = Number(fromVar);
    if (Number.isFinite(parsed) && parsed > 0 && parsed <= 65535) {
      return parsed;
    }
  }
  const fromEnv = Number(Deno.env.get("NVIM_MCP_PORT") ?? "");
  if (Number.isFinite(fromEnv) && fromEnv > 0 && fromEnv <= 65535) {
    return fromEnv;
  }
  return DEFAULT_PORT;
}

async function listBuffers(
  denops: Denops,
  options: { dir?: string; modifiedOnly?: boolean; limit?: number },
): Promise<BufferInfo[]> {
  const bufinfos = await fn.getbufinfo(denops);
  const buffers = await Promise.all(bufinfos.map(async (bufinfo) => {
    const buftype = await fn.getbufvar(denops, bufinfo.bufnr, "&buftype");
    const modified = await fn.getbufvar(denops, bufinfo.bufnr, "&modified");
    return {
      name: bufinfo.name,
      bufnr: bufinfo.bufnr,
      modified: modified === 1,
      buftype: String(buftype),
      listed: bufinfo.listed === 1,
      loaded: bufinfo.loaded === 1,
    };
  }));

  let filtered = buffers.filter((buf) => buf.name !== "");
  if (options.modifiedOnly) {
    filtered = filtered.filter((buf) => buf.modified);
  }
  if (options.dir) {
    const prefix = options.dir.endsWith("/") ? options.dir : `${options.dir}/`;
    filtered = filtered.filter((buf) => buf.name.startsWith(prefix));
  }
  if (typeof options.limit === "number") {
    filtered = filtered.slice(0, options.limit);
  }
  return filtered;
}

async function getCurrentBuffer(denops: Denops) {
  const bufnr = await fn.bufnr(denops, "%");
  const name = await fn.bufname(denops, bufnr);
  const modified = await fn.getbufvar(denops, bufnr, "&modified");
  const [, line, col] = await fn.getcurpos(denops);
  const cwd = await fn.getcwd(denops);
  return {
    name: String(name),
    bufnr,
    modified: modified === 1,
    cursor: { line, col },
    cwd,
  };
}
