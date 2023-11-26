import type {} from "https://deno.land/x/denops_std@v5.0.2/mod.ts";
import type { GatherArguments } from "https://deno.land/x/ddu_vim@v3.6.0/base/source.ts";
import { BaseSource } from "https://deno.land/x/ddu_vim@v3.6.0/types.ts";
import type { Item } from "https://deno.land/x/ddu_vim@v3.6.0/types.ts";

type ActionData = Record<PropertyKey, never>;

type Params = Record<PropertyKey, never>;

export class Source extends BaseSource<Params, ActionData> {
  override kind = "todo";

  override gather(
    args: GatherArguments<Params>,
  ): ReadableStream<Item<ActionData>[]> {
  }

  override params(): Params {
    return {};
  }
}
