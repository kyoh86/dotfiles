import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { isTruthy } from "../util.ts";

export async function getCurrentBuffer(denops: Denops) {
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

export async function getCwd(denops: Denops) {
  const cwd = await fn.getcwd(denops);
  return { cwd };
}

export async function getCurrentSelection(denops: Denops) {
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
