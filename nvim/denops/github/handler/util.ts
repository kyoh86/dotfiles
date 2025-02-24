import * as func from "jsr:@denops/std@~7.5.0/function";
import * as mapping from "jsr:@denops/std@~7.5.0/mapping";
import type { MapOptions } from "jsr:@denops/std@7/mapping";
import type { Denops } from "jsr:@denops/std@~7.5.0";

export async function mapDispatch(
  args: {
    denops: Denops;
    lhs: string;
    method: string;
    sync?: boolean;
    name?: string;
    args?: unknown[];
  } & MapOptions,
): Promise<void> {
  const { denops, lhs, method, ...opts } = {
    sync: false,
    name: args.denops.name,
    args: [],
    mode: "n",
    ...args,
  };
  return await mapping.map(
    denops,
    lhs,
    `<cmd>call denops#${opts.sync ? "request" : "notify"}(${await func.string(
      denops,
      opts.name,
    )}, ${await func.string(denops, method)}, ${await func.string(
      denops,
      opts.args,
    )})<cr>`,
  );
}
