import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import * as z from "zod";
import { isTruthy } from "../util.ts";

type BufferInfo = {
  name: string;
  bufnr: number;
  modified: boolean;
  buftype: string;
  listed: boolean;
  loaded: boolean;
};

export function registerBufferTools(
  server: McpServer,
  denops: Denops,
): void {
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
      modified: isTruthy(modified),
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
