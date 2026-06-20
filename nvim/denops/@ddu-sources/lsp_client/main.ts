import type {} from "@denops/std";
import type { GatherArguments } from "@shougo/ddu-vim/source";
import type { Item } from "@shougo/ddu-vim/types";
import { BaseSource } from "@shougo/ddu-vim/source";
import {
  type ActionData,
  isActionData,
} from "../../@ddu-kinds/lsp_client/main.ts";
import { ensure, is } from "@core/unknownutil";

type Params = Record<PropertyKey, never>;

export class Source extends BaseSource<Params, ActionData> {
  override kind = "lsp_client";
  override gather(
    { denops }: GatherArguments<Params>,
  ): ReadableStream<Item<ActionData>[]> {
    return new ReadableStream<Item<ActionData>[]>({
      start: async (controller) => {
        const res = await denops.call(
          "luaeval",
          `require("kyoh86.lib.lsp_client").get_convertible_clients()`,
          {},
        );
        const clients = ensure(res, is.ArrayOf(isActionData));
        controller.enqueue(
          clients.map((v) => {
            return v
              ? {
                word: v.name,
                action: v,
              }
              : undefined;
          }).filter((v) => !!v),
        );
        controller.close();
      },
    });
  }

  override params(): Params {
    return {};
  }
}
