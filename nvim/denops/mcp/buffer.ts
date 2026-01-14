import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { isTruthy } from "./util.ts";

export type BufferMatchMode = "exact" | "suffix" | "contains";

export type BufferMatch = {
  bufnr: number;
  name: string;
};

export type BufferResolveResult =
  | { ok: true; bufnr: number; name: string }
  | { ok: false; reason: string; candidates?: BufferMatch[] };

export async function resolveBuffer(
  denops: Denops,
  options: { bufnr?: number; name?: string; match?: BufferMatchMode },
): Promise<BufferResolveResult> {
  if (typeof options.bufnr === "number") {
    const exists = await fn.bufexists(denops, options.bufnr);
    if (!isTruthy(exists)) {
      return { ok: false, reason: "not found" };
    }
    const name = String(await fn.bufname(denops, options.bufnr));
    return { ok: true, bufnr: options.bufnr, name };
  }
  const rawName = options.name?.trim() ?? "";
  if (rawName === "") {
    return { ok: false, reason: "missing bufnr or name" };
  }
  const matchMode: BufferMatchMode = options.match ?? "suffix";
  const bufinfos = await fn.getbufinfo(denops);
  const matches = bufinfos.filter((bufinfo) => {
    const name = String(bufinfo.name ?? "");
    if (name === "") {
      return false;
    }
    return matchName(name, rawName, matchMode);
  });
  if (matches.length === 0) {
    return { ok: false, reason: "not found" };
  }
  if (matches.length > 1) {
    return {
      ok: false,
      reason: "ambiguous",
      candidates: matches.map((bufinfo) => ({
        bufnr: bufinfo.bufnr,
        name: String(bufinfo.name ?? ""),
      })),
    };
  }
  const match = matches[0];
  return { ok: true, bufnr: match.bufnr, name: String(match.name ?? "") };
}

function matchName(
  bufname: string,
  target: string,
  mode: BufferMatchMode,
): boolean {
  switch (mode) {
    case "exact":
      return bufname === target;
    case "contains":
      return bufname.includes(target);
    case "suffix":
    default:
      return bufname.endsWith(target);
  }
}
