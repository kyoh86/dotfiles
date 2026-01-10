import type { Denops } from "@denops/std";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import * as z from "zod";

export function registerDiagnosticsTool(
  server: McpServer,
  denops: Denops,
): void {
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
