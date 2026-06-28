import type { Denops } from "@denops/std";
import { resolveBuffer } from "../buffer.ts";

type DiagnosticsOptions = {
  bufnr?: number;
  name?: string;
  match?: "exact" | "suffix" | "contains";
  severity?: "error" | "warn" | "info" | "hint";
};

export async function getDiagnostics(
  denops: Denops,
  options: DiagnosticsOptions,
) {
  let target = 0;
  if (options.bufnr !== undefined || options.name) {
    const resolved = await resolveBuffer(denops, {
      bufnr: options.bufnr,
      name: options.name,
      match: options.match,
    });
    if (!resolved.ok) {
      return {
        total: 0,
        diagnostics: [],
        reason: resolved.reason,
        candidates: resolved.candidates,
      };
    }
    target = resolved.bufnr;
  }
  const severity = options.severity ?? "";
  const diagnostics = await denops.call(
    "kyoh86#mcp#diagnostics",
    target,
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
