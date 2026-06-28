import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { resolveBuffer } from "../buffer.ts";
import { isTruthy } from "../util.ts";

type BufferInfo = {
  name: string;
  bufnr: number;
  modified: boolean;
  buftype: string;
  listed: boolean;
  loaded: boolean;
};

type ListBuffersOptions = {
  dir?: string;
  modifiedOnly?: boolean;
  limit?: number;
};

type ResolveBufferOptions = {
  bufnr?: number;
  name?: string;
  match?: "exact" | "suffix" | "contains";
};

type GetBufferContentOptions = ResolveBufferOptions & {
  start?: number;
  end?: number;
  limit?: number;
};

type OpenFileOptions = {
  path: string;
  focus?: boolean;
};

export async function listBuffers(
  denops: Denops,
  options: ListBuffersOptions,
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

export async function reloadBuffer(
  denops: Denops,
  options: ResolveBufferOptions,
): Promise<{
  bufnr: number;
  name: string;
  reloaded: boolean;
  reason?: string;
  candidates?: { bufnr: number; name: string }[];
}> {
  const resolved = options.bufnr === undefined && !options.name
    ? await (async () => {
      const bufnr = await fn.bufnr(denops, "%");
      const name = String(await fn.bufname(denops, bufnr));
      return { ok: true as const, bufnr, name };
    })()
    : await resolveBuffer(denops, options);
  if (!resolved.ok) {
    return {
      bufnr: options.bufnr ?? 0,
      name: "",
      reloaded: false,
      reason: resolved.reason,
      candidates: resolved.candidates,
    };
  }
  const { bufnr, name } = resolved;
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

export async function getBufferContent(
  denops: Denops,
  options: {
    bufnr?: number;
    name?: string;
    match?: "exact" | "suffix" | "contains";
    start?: number;
    end?: number;
    limit?: number;
  },
): Promise<{
  bufnr: number;
  name: string;
  start: number;
  end: number;
  total: number;
  truncated: boolean;
  lines: string[];
  reason?: string;
  candidates?: { bufnr: number; name: string }[];
}> {
  const resolved = options.bufnr === undefined && !options.name
    ? await (async () => {
      const bufnr = await fn.bufnr(denops, "%");
      const name = String(await fn.bufname(denops, bufnr));
      return { ok: true as const, bufnr, name };
    })()
    : await resolveBuffer(denops, options);
  if (!resolved.ok) {
    return {
      bufnr: options.bufnr ?? 0,
      name: "",
      start: 0,
      end: 0,
      total: 0,
      truncated: false,
      lines: [],
      reason: resolved.reason,
      candidates: resolved.candidates,
    };
  }
  const { bufnr, name } = resolved;
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

export async function saveBuffer(
  denops: Denops,
  options: {
    bufnr?: number;
    name?: string;
    match?: "exact" | "suffix" | "contains";
  },
): Promise<{
  bufnr: number;
  name: string;
  saved: boolean;
  reason?: string;
  candidates?: { bufnr: number; name: string }[];
}> {
  const resolved = options.bufnr === undefined && !options.name
    ? await (async () => {
      const bufnr = await fn.bufnr(denops, "%");
      const name = String(await fn.bufname(denops, bufnr));
      return { ok: true as const, bufnr, name };
    })()
    : await resolveBuffer(denops, options);
  if (!resolved.ok) {
    return {
      bufnr: options.bufnr ?? 0,
      name: "",
      saved: false,
      reason: resolved.reason,
      candidates: resolved.candidates,
    };
  }
  const { bufnr, name } = resolved;
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

export async function openFile(
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
