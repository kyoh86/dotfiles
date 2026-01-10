import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import * as z from "zod";

export function registerListItemsTool(
  server: McpServer,
  denops: Denops,
): void {
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
