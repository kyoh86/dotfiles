import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import * as path from "@std/path";
import * as z from "zod";

const DEFAULT_CONTEXT = 4;
const DEFAULT_LIMIT = 3;

export function registerHelpTool(server: McpServer, denops: Denops): void {
  server.registerTool(
    "help_query",
    {
      title: "Query Neovim help tags",
      description:
        "Search Neovim help tags and return context from the matching help file.",
      inputSchema: z.object({
        query: z.string().min(1),
        context: z.number().int().positive().optional(),
        limit: z.number().int().positive().optional(),
      }).strict(),
      outputSchema: z.object({
        query: z.string(),
        total: z.number().int(),
        matches: z.array(z.object({
          tag: z.string(),
          file: z.string(),
          path: z.string(),
          excmd: z.string(),
          tagfile: z.string(),
          matchedBy: z.enum(["exact", "prefix"]),
          found: z.boolean(),
          line: z.number().int(),
          start: z.number().int(),
          end: z.number().int(),
          context: z.array(z.string()),
        })),
      }),
    },
    async ({ query, context, limit }) => {
      const payload = await queryHelp(denops, {
        query,
        context: context ?? DEFAULT_CONTEXT,
        limit: limit ?? DEFAULT_LIMIT,
      });
      return {
        content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
        structuredContent: payload,
      };
    },
  );
}

async function queryHelp(
  denops: Denops,
  options: { query: string; context: number; limit: number },
) {
  const tags = await listHelpTags(denops, options.query);
  if (tags.length === 0) {
    return { query: options.query, total: 0, matches: [] };
  }
  const exact = tags.filter((tag) => tag === options.query);
  const prefix = tags.filter((tag) =>
    tag !== options.query && tag.startsWith(options.query)
  );
  const matched = [
    ...exact.map((tag) => ({ tag, matchedBy: "exact" as const })),
    ...prefix.map((tag) => ({ tag, matchedBy: "prefix" as const })),
  ];
  const limited = matched.slice(0, options.limit);
  const matches = await Promise.all(
    limited.map(({ tag, matchedBy }) =>
      readHelpContext(denops, tag, options.context, matchedBy)
    ),
  );
  return {
    query: options.query,
    total: matched.length,
    matches,
  };
}

async function listHelpTags(
  denops: Denops,
  query: string,
): Promise<string[]> {
  const raw = await fn.getcompletion(denops, query, "help");
  const tags = Array.isArray(raw) ? raw : [raw];
  const unique = new Set(
    tags.filter((tag): tag is string => typeof tag === "string" && tag !== ""),
  );
  return Array.from(unique);
}

async function readHelpContext(
  denops: Denops,
  tag: string,
  context: number,
  matchedBy: "exact" | "prefix",
) {
  const originalWin = await fn.win_getid(denops);
  const originalBuf = await fn.bufnr(denops, "%");
  const helpWinsBefore = await listHelpWindows(denops);
  let helpWin = originalWin;
  let helpBuf = originalBuf;
  try {
    const escaped = await fn.escape(denops, tag, " \\");
    await denops.call(
      "execute",
      `silent keepjumps keepalt help ${escaped}`,
    );
    helpWin = await fn.win_getid(denops);
    helpBuf = await fn.bufnr(denops, "%");
    const name = String(await fn.bufname(denops, helpBuf));
    const file = name ? path.basename(name) : "";
    const line = Number(await fn.line(denops, "."));
    const total = Number(await fn.line(denops, "$"));
    const start = Math.max(1, line - context);
    const end = Math.min(total, line + context);
    const lines = await fn.getline(denops, start, end);
    return {
      tag,
      file,
      path: name,
      excmd: `help ${tag}`,
      tagfile: "",
      matchedBy,
      found: true,
      line,
      start,
      end,
      context: Array.isArray(lines) ? lines.map(String) : [String(lines)],
    };
  } catch {
    return {
      tag,
      file: "",
      path: "",
      excmd: "",
      tagfile: "",
      matchedBy,
      found: false,
      line: 0,
      start: 0,
      end: 0,
      context: [],
    };
  } finally {
    const shouldClose = helpWin !== originalWin &&
      helpBuf !== originalBuf &&
      !helpWinsBefore.has(helpWin);
    if (shouldClose) {
      try {
        try {
          await denops.call("nvim_win_close", helpWin, true);
        } catch {
          await fn.win_gotoid(denops, helpWin);
          await denops.call("close");
        }
      } catch {
        // ignore cleanup errors
      }
    } else if (helpWin === originalWin && helpBuf !== originalBuf) {
      try {
        await denops.call(
          "execute",
          `silent keepalt keepjumps buffer ${originalBuf}`,
        );
      } catch {
        // ignore restore errors
      }
    }
    try {
      await fn.win_gotoid(denops, originalWin);
    } catch {
      // ignore restore errors
    }
  }
}

async function listHelpWindows(denops: Denops): Promise<Set<number>> {
  const wininfo = await fn.getwininfo(denops);
  const wins = Array.isArray(wininfo) ? wininfo : [];
  const helpWins: number[] = [];
  for (const win of wins) {
    if (!win || typeof win !== "object") {
      continue;
    }
    const winid = (win as { winid?: number }).winid;
    const bufnr = (win as { bufnr?: number }).bufnr;
    if (!winid || !bufnr) {
      continue;
    }
    const buftype = await fn.getbufvar(denops, bufnr, "&buftype");
    if (buftype === "help") {
      helpWins.push(winid);
    }
  }
  return new Set(helpWins);
}
