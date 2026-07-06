import type { Denops } from "@denops/std";
import { parse } from "@denops/std/bufname";
import * as fn from "@denops/std/function";

type SourceKind = "head" | "index" | "ours" | "theirs" | "revision";

export type GinBufferSource = {
  scheme: "ginedit";
  worktree: string;
  params: Record<string, string | string[] | undefined>;
  fragment: string;
  source: SourceKind;
  sourceLabel: string;
};

const cacheVars = [
  "my_gin_scheme",
  "my_gin_worktree",
  "my_gin_params",
  "my_gin_fragment",
  "my_gin_source",
  "my_gin_source_label",
];

export function parseGinBufferSource(
  bufname: string,
): GinBufferSource | undefined {
  const parsed = parse(bufname);
  if (parsed.scheme !== "ginedit") {
    return undefined;
  }

  const params = parsed.params ?? {};
  const commitish = firstParam(params.commitish);
  const [source, sourceLabel] = sourceFromCommitish(commitish);

  return {
    scheme: "ginedit",
    worktree: parsed.expr,
    params,
    fragment: parsed.fragment ?? "",
    source,
    sourceLabel,
  };
}

function firstParam(value: string | string[] | undefined): string | undefined {
  if (Array.isArray(value)) {
    return value[0];
  }
  return value;
}

function sourceFromCommitish(
  commitish: string | undefined,
): [SourceKind, string] {
  if (!commitish) {
    return ["index", "INDEX"];
  }
  switch (commitish) {
    case "HEAD":
      return ["head", "HEAD"];
    case ":2":
      return ["ours", "OURS"];
    case ":3":
      return ["theirs", "THEIRS"];
    default:
      return ["revision", commitish];
  }
}

async function clearCache(denops: Denops, bufnr: number): Promise<void> {
  await Promise.all(
    cacheVars.map((name) => fn.setbufvar(denops, bufnr, name, "")),
  );
}

async function setCache(
  denops: Denops,
  bufnr: number,
  source: GinBufferSource,
): Promise<void> {
  await Promise.all([
    fn.setbufvar(denops, bufnr, "my_gin_scheme", source.scheme),
    fn.setbufvar(denops, bufnr, "my_gin_worktree", source.worktree),
    fn.setbufvar(denops, bufnr, "my_gin_params", source.params),
    fn.setbufvar(denops, bufnr, "my_gin_fragment", source.fragment),
    fn.setbufvar(denops, bufnr, "my_gin_source", source.source),
    fn.setbufvar(denops, bufnr, "my_gin_source_label", source.sourceLabel),
  ]);
}

export function main(denops: Denops): void {
  denops.dispatcher = {
    cache: async (unknownBufnr: unknown) => {
      const bufnr = Number(unknownBufnr);
      if (!Number.isInteger(bufnr) || bufnr <= 0) {
        return;
      }

      const name = String(await fn.bufname(denops, bufnr));
      let source: GinBufferSource | undefined;
      try {
        source = parseGinBufferSource(name);
      } catch {
        source = undefined;
      }

      if (!source) {
        await clearCache(denops, bufnr);
        return;
      }
      await setCache(denops, bufnr, source);
    },
  };
}
