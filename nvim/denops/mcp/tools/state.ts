import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import * as z from "zod";
import { isTruthy } from "../util.ts";

export function registerStateTools(
  server: McpServer,
  denops: Denops,
): void {
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
    modified: isTruthy(modified),
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
