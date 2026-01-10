import * as vars from "@denops/std/variable";
import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import * as z from "zod";

const DEFAULT_PORT = 0;
const LOCAL_HOST = "127.0.0.1";
const REGISTER_RETRY_LIMIT = 5;
const REGISTER_BACKOFF_BASE_MS = 200;

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

  server.registerTool(
    "nvim_cwd",
    {
      title: "Get Neovim working directory",
      description: "Return the current working directory in Neovim.",
      inputSchema: z.object({}).strict(),
      outputSchema: z.object({
        cwd: z.string(),
      }),
    },
    async () => {
      const payload = await getCwd(denops);
      return {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        structuredContent: payload,
      };
    },
  );

  server.registerTool(
    "nvim_current_selection",
    {
      title: "Get current selection",
      description: "Return the current visual selection, if any.",
      inputSchema: z.object({}).strict(),
      outputSchema: z.object({
        hasSelection: z.boolean(),
        mode: z.string(),
        start: z.object({
          line: z.number().int(),
          col: z.number().int(),
        }).optional(),
        end: z.object({
          line: z.number().int(),
          col: z.number().int(),
        }).optional(),
        lines: z.array(z.string()),
        text: z.string(),
      }),
    },
    async () => {
      const selection = await getCurrentSelection(denops);
      return {
        content: [{ type: "text", text: JSON.stringify(selection, null, 2) }],
        structuredContent: selection,
      };
    },
  );

  server.registerTool(
    "nvim_list_items",
    {
      title: "Get quickfix or loclist items",
      description: "Return quickfix or location list items.",
      inputSchema: z.object({
        list: z.enum(["quickfix", "loclist"]).optional(),
        winid: z.number().int().positive().optional(),
        limit: z.number().int().positive().optional(),
      }).strict(),
      outputSchema: z.object({
        list: z.string(),
        title: z.string().optional(),
        total: z.number().int(),
        items: z.array(z.object({
          bufnr: z.number().int(),
          filename: z.string(),
          lnum: z.number().int(),
          col: z.number().int(),
          end_lnum: z.number().int().optional(),
          end_col: z.number().int().optional(),
          text: z.string(),
          type: z.string().optional(),
          valid: z.boolean(),
        })),
      }),
    },
    async ({ list, winid, limit }) => {
      const payload = await getListItems(denops, {
        list: list ?? "quickfix",
        winid,
        limit,
      });
      return {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        structuredContent: payload,
      };
    },
  );

  server.registerTool(
    "nvim_diagnostics",
    {
      title: "Get LSP diagnostics",
      description: "Return diagnostics from Neovim's built-in diagnostic API.",
      inputSchema: z.object({
        bufnr: z.number().int().optional(),
        severity: z.enum(["error", "warn", "info", "hint"]).optional(),
      }).strict(),
      outputSchema: z.object({
        total: z.number().int(),
        diagnostics: z.array(z.object({
          bufnr: z.number().int(),
          lnum: z.number().int(),
          col: z.number().int(),
          end_lnum: z.number().int().optional(),
          end_col: z.number().int().optional(),
          severity: z.number().int(),
          severity_name: z.string(),
          message: z.string(),
          source: z.string().optional(),
          code: z.union([z.string(), z.number()]).optional(),
        })),
      }),
    },
    async ({ bufnr, severity }) => {
      const payload = await getDiagnostics(denops, { bufnr, severity });
      return {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        structuredContent: payload,
      };
    },
  );

  server.registerTool(
    "nvim_reload_buffer",
    {
      title: "Reload buffer from disk",
      description: "Reload a buffer without changing the current window.",
      inputSchema: z.object({
        bufnr: z.number().int().optional(),
      }).strict(),
      outputSchema: z.object({
        bufnr: z.number().int(),
        name: z.string(),
        reloaded: z.boolean(),
        reason: z.string().optional(),
      }),
    },
    async ({ bufnr }) => {
      const payload = await reloadBuffer(denops, { bufnr });
      return {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        structuredContent: payload,
      };
    },
  );

  server.registerTool(
    "nvim_get_buffer_content",
    {
      title: "Get buffer content",
      description: "Return buffer lines without changing the current window.",
      inputSchema: z.object({
        bufnr: z.number().int().optional(),
        start: z.number().int().positive().optional(),
        end: z.number().int().positive().optional(),
        limit: z.number().int().positive().optional(),
      }).strict(),
      outputSchema: z.object({
        bufnr: z.number().int(),
        name: z.string(),
        start: z.number().int(),
        end: z.number().int(),
        total: z.number().int(),
        truncated: z.boolean(),
        lines: z.array(z.string()),
        reason: z.string().optional(),
      }),
    },
    async ({ bufnr, start, end, limit }) => {
      const payload = await getBufferContent(denops, {
        bufnr,
        start,
        end,
        limit,
      });
      return {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        structuredContent: payload,
      };
    },
  );

  server.registerTool(
    "nvim_save_buffer",
    {
      title: "Save buffer",
      description:
        "Write a buffer to disk without changing the current window.",
      inputSchema: z.object({
        bufnr: z.number().int().optional(),
      }).strict(),
      outputSchema: z.object({
        bufnr: z.number().int(),
        name: z.string(),
        saved: z.boolean(),
        reason: z.string().optional(),
      }),
    },
    async ({ bufnr }) => {
      const payload = await saveBuffer(denops, { bufnr });
      return {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        structuredContent: payload,
      };
    },
  );

  server.registerTool(
    "nvim_open_file",
    {
      title: "Open file",
      description:
        "Open a file, optionally without changing the current window.",
      inputSchema: z.object({
        path: z.string(),
        focus: z.boolean().optional(),
      }).strict(),
      outputSchema: z.object({
        bufnr: z.number().int(),
        name: z.string(),
        opened: z.boolean(),
        focused: z.boolean(),
        reason: z.string().optional(),
      }),
    },
    async ({ path, focus }) => {
      const payload = await openFile(denops, { path, focus });
      return {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        structuredContent: payload,
      };
    },
  );

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
      listed: Boolean(bufinfo.listed),
      loaded: Boolean(bufinfo.loaded),
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

async function getCwd(denops: Denops) {
  const cwd = await fn.getcwd(denops);
  return { cwd };
}

async function getCurrentSelection(denops: Denops) {
  const mode = String(await fn.mode(denops));
  if (mode === "\u0016") {
    return {
      hasSelection: false,
      mode,
      lines: [],
      text: "",
    };
  }
  const startPos = await fn.getpos(denops, "'<");
  const endPos = await fn.getpos(denops, "'>");
  const [, startLine, startCol] = startPos;
  const [, endLine, endCol] = endPos;
  if (startLine === 0 || endLine === 0) {
    return {
      hasSelection: false,
      mode,
      lines: [],
      text: "",
    };
  }
  const normalized = normalizeRange(
    { line: startLine, col: startCol },
    { line: endLine, col: endCol },
  );
  const lines = await fn.getline(
    denops,
    normalized.start.line,
    normalized.end.line,
  );
  const sliced = sliceLines(
    lines,
    normalized.start.col,
    normalized.end.col,
  );
  return {
    hasSelection: true,
    mode,
    start: normalized.start,
    end: normalized.end,
    lines: sliced,
    text: sliced.join("\n"),
  };
}

function normalizeRange(
  start: { line: number; col: number },
  end: { line: number; col: number },
) {
  if (
    start.line > end.line || (start.line === end.line && start.col > end.col)
  ) {
    return { start: end, end: start };
  }
  return { start, end };
}

function sliceLines(lines: string[], startCol: number, endCol: number) {
  if (lines.length === 0) {
    return [];
  }
  if (lines.length === 1) {
    return [sliceLine(lines[0], startCol, endCol)];
  }
  const first = sliceLine(lines[0], startCol, lines[0].length + 1);
  const last = sliceLine(lines[lines.length - 1], 1, endCol);
  return [first, ...lines.slice(1, -1), last];
}

function sliceLine(line: string, startCol: number, endCol: number) {
  const start = Math.max(startCol - 1, 0);
  const end = Math.max(endCol, 0);
  return line.slice(start, end);
}

function formatZodError(error: z.ZodError) {
  return error.issues.map((issue) => {
    const path = issue.path.length === 0 ? "(root)" : issue.path.join(".");
    return `${path}: ${issue.message}`;
  }).join("; ");
}

function logError(prefix: string, error: unknown) {
  if (error instanceof z.ZodError) {
    console.error(prefix, formatZodError(error));
    return;
  }
  if (error instanceof Error) {
    console.error(prefix, error.message);
    return;
  }
  console.error(prefix, String(error));
}

async function getListItems(
  denops: Denops,
  options: { list: "quickfix" | "loclist"; winid?: number; limit?: number },
) {
  if (options.list === "loclist") {
    const winid = options.winid ?? await fn.win_getid(denops);
    const loc = await fn.getloclist(denops, winid, { all: 1 });
    return formatListItems(denops, loc, "loclist", options.limit);
  }
  const qf = await fn.getqflist(denops, { all: 1 });
  return formatListItems(denops, qf, "quickfix", options.limit);
}

async function formatListItems(
  denops: Denops,
  list: { items?: unknown[]; title?: unknown },
  kind: "quickfix" | "loclist",
  limit?: number,
) {
  const rawItems = Array.isArray(list.items) ? list.items : [];
  const items = await Promise.all(rawItems.map(async (item) => {
    const record = item as Record<string, unknown>;
    const bufnr = Number(record.bufnr ?? 0);
    let filename = typeof record.filename === "string"
      ? record.filename
      : String(record.filename ?? "");
    if (filename === "" && bufnr > 0) {
      filename = String(await fn.bufname(denops, bufnr));
    }
    return {
      bufnr,
      filename,
      lnum: Number(record.lnum ?? 0),
      col: Number(record.col ?? 0),
      end_lnum: record.end_lnum === undefined
        ? undefined
        : Number(record.end_lnum),
      end_col: record.end_col === undefined
        ? undefined
        : Number(record.end_col),
      text: String(record.text ?? ""),
      type: typeof record.type === "string" ? record.type : undefined,
      valid: Boolean(record.valid ?? true),
    };
  }));
  const sliced = typeof limit === "number" ? items.slice(0, limit) : items;
  return {
    list: kind,
    title: typeof list.title === "string" ? list.title : undefined,
    total: items.length,
    items: sliced,
  };
}

async function getDiagnostics(
  denops: Denops,
  options: { bufnr?: number; severity?: "error" | "warn" | "info" | "hint" },
) {
  const bufnr = options.bufnr ?? 0;
  const severity = options.severity ?? "";
  const diagnostics = await denops.call(
    "kyoh86#mcp#diagnostics",
    bufnr,
    severity,
  ) as Array<Record<string, unknown>>;
  return {
    total: diagnostics.length,
    diagnostics: diagnostics.map((item) => ({
      bufnr: Number(item.bufnr ?? 0),
      lnum: Number(item.lnum ?? 0),
      col: Number(item.col ?? 0),
      end_lnum: item.end_lnum === undefined ? undefined : Number(item.end_lnum),
      end_col: item.end_col === undefined ? undefined : Number(item.end_col),
      severity: Number(item.severity ?? 0),
      severity_name: String(item.severity_name ?? ""),
      message: String(item.message ?? ""),
      source: item.source === undefined ? undefined : String(item.source),
      code: item.code as string | number | undefined,
    })),
  };
}

async function reloadBuffer(
  denops: Denops,
  options: { bufnr?: number },
): Promise<
  { bufnr: number; name: string; reloaded: boolean; reason?: string }
> {
  const bufnr = options.bufnr ?? await fn.bufnr(denops, "%");
  const exists = await fn.bufexists(denops, bufnr);
  if (!isTruthy(exists)) {
    return { bufnr, name: "", reloaded: false, reason: "not found" };
  }
  const name = String(await fn.bufname(denops, bufnr));
  if (name === "") {
    return { bufnr, name, reloaded: false, reason: "no name" };
  }
  const buftype = String(await fn.getbufvar(denops, bufnr, "&buftype"));
  if (buftype !== "") {
    return {
      bufnr,
      name,
      reloaded: false,
      reason: `unsupported buftype: ${buftype}`,
    };
  }
  const modified = await fn.getbufvar(denops, bufnr, "&modified");
  if (isTruthy(modified)) {
    return { bufnr, name, reloaded: false, reason: "modified" };
  }
  const loaded = await fn.bufloaded(denops, bufnr);
  if (!isTruthy(loaded)) {
    await fn.bufload(denops, bufnr);
  }
  await denops.cmd(`checktime ${bufnr}`);
  return { bufnr, name, reloaded: true };
}

async function getBufferContent(
  denops: Denops,
  options: { bufnr?: number; start?: number; end?: number; limit?: number },
): Promise<{
  bufnr: number;
  name: string;
  start: number;
  end: number;
  total: number;
  truncated: boolean;
  lines: string[];
  reason?: string;
}> {
  const bufnr = options.bufnr ?? await fn.bufnr(denops, "%");
  const exists = await fn.bufexists(denops, bufnr);
  if (!isTruthy(exists)) {
    return {
      bufnr,
      name: "",
      start: 0,
      end: 0,
      total: 0,
      truncated: false,
      lines: [],
      reason: "not found",
    };
  }
  const name = String(await fn.bufname(denops, bufnr));
  const loaded = await fn.bufloaded(denops, bufnr);
  if (!isTruthy(loaded)) {
    await fn.bufload(denops, bufnr);
  }
  const start = Math.max(options.start ?? 1, 1);
  const rawEnd = options.end;
  const rawLines = rawEnd === undefined
    ? await fn.getbufline(denops, bufnr, start, "$")
    : await fn.getbufline(denops, bufnr, start, rawEnd);
  const total = rawLines.length;
  let lines = rawLines;
  let truncated = false;
  if (typeof options.limit === "number" && lines.length > options.limit) {
    lines = lines.slice(0, options.limit);
    truncated = true;
  }
  const end = rawEnd === undefined
    ? start + Math.max(total - 1, 0)
    : Math.max(rawEnd, start);
  return {
    bufnr,
    name,
    start,
    end,
    total,
    truncated,
    lines,
  };
}

async function saveBuffer(
  denops: Denops,
  options: { bufnr?: number },
): Promise<{ bufnr: number; name: string; saved: boolean; reason?: string }> {
  const bufnr = options.bufnr ?? await fn.bufnr(denops, "%");
  const exists = await fn.bufexists(denops, bufnr);
  if (!isTruthy(exists)) {
    return { bufnr, name: "", saved: false, reason: "not found" };
  }
  const name = String(await fn.bufname(denops, bufnr));
  if (name === "") {
    return { bufnr, name, saved: false, reason: "no name" };
  }
  const buftype = String(await fn.getbufvar(denops, bufnr, "&buftype"));
  if (buftype !== "") {
    return {
      bufnr,
      name,
      saved: false,
      reason: `unsupported buftype: ${buftype}`,
    };
  }
  const modified = await fn.getbufvar(denops, bufnr, "&modified");
  if (!isTruthy(modified)) {
    return { bufnr, name, saved: false, reason: "not modified" };
  }
  const loaded = await fn.bufloaded(denops, bufnr);
  if (!isTruthy(loaded)) {
    await fn.bufload(denops, bufnr);
  }
  await denops.call(
    "bufcall",
    bufnr,
    "execute('silent keepalt keepjumps keepmarks write')",
  );
  return { bufnr, name, saved: true };
}

async function openFile(
  denops: Denops,
  options: { path: string; focus?: boolean },
): Promise<{
  bufnr: number;
  name: string;
  opened: boolean;
  focused: boolean;
  reason?: string;
}> {
  const path = options.path.trim();
  if (path === "") {
    return {
      bufnr: 0,
      name: "",
      opened: false,
      focused: false,
      reason: "empty path",
    };
  }
  if (options.focus) {
    const escaped = String(await fn.fnameescape(denops, path));
    await denops.cmd(`edit ${escaped}`);
    const bufnr = await fn.bufnr(denops, "%");
    const name = String(await fn.bufname(denops, bufnr));
    return { bufnr, name, opened: true, focused: true };
  }
  let bufnr = await fn.bufnr(denops, path);
  let opened = false;
  if (bufnr <= 0) {
    bufnr = await fn.bufadd(denops, path);
    opened = true;
  }
  const loaded = await fn.bufloaded(denops, bufnr);
  if (!isTruthy(loaded)) {
    await fn.bufload(denops, bufnr);
  }
  const name = String(await fn.bufname(denops, bufnr));
  return { bufnr, name, opened, focused: false };
}

function isTruthy(value: unknown): boolean {
  if (typeof value === "boolean") {
    return value;
  }
  if (typeof value === "number") {
    return value !== 0;
  }
  return Boolean(value);
}
