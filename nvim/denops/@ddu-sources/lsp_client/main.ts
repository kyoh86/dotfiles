import type {} from "@denops/std";
import type { GatherArguments } from "@shougo/ddu-vim/source";
import type { Item } from "@shougo/ddu-vim/types";
import { BaseSource } from "@shougo/ddu-vim/source";
import {
  type ActionData,
  isActionData,
} from "../../@ddu-kinds/lsp_client/main.ts";
import { ensure, is } from "@core/unknownutil";

import { pathShorten } from "../../lib/path_shorten.ts";

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
          clients.map(formatItem).filter((v) => !!v),
        );
        controller.close();
      },
    });
  }

  override params(): Params {
    return {};
  }
}

function formatItem(action?: ActionData) {
  if (!action) {
    return undefined;
  }
  const ret = {
    word: action.name,
    action,
    highlights: [{
      name: "ddu-kind-lsp_client-name",
      hl_group: "Title",
      col: 1,
      width: action.name.length,
    }],
  };
  if (action.root_dir) {
    const shorten = pathShorten(action.root_dir);
    ret.word += " " + shorten;
    ret.highlights.push({
      name: "ddu-kind-lsp_client-root_dir",
      hl_group: "String",
      col: action.name.length + 2,
      width: shorten.length,
    });
  }
  const bufs = Object.entries(action.attached_buffers).map((entry) => {
    return `${entry[0]}(${entry[1]})`;
  }).join(", ");
  if (bufs && bufs !== "") {
    ret.word += " for buffer " + bufs;
  }
  return ret;
}
