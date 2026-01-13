import type { DduItem, ItemHighlight } from "@shougo/ddu-vim/types";
import { BaseColumn, GetBaseTextArguments } from "@shougo/ddu-vim/column";
import type { GetTextArguments, GetTextResult } from "@shougo/ddu-vim/column";
import type { Denops } from "@denops/std";
import * as fn from "@denops/std/function";
import type { ActionData } from "../../@ddu-kinds/codex_session/main.ts";

type Params = {
  limitLength: number;
};

export abstract class CodexSessionBaseColumn extends BaseColumn<Params> {
  #width = 1;

  override getBaseText(
    {}: GetBaseTextArguments<Params>,
  ): string {
    return "";
  }

  abstract getAttr(denops: Denops, {}: ActionData): {
    rawText: string;
    highlights?: ItemHighlight[];
  };

  override async getLength(args: {
    denops: Denops;
    columnParams: Params;
    items: DduItem[];
  }): Promise<number> {
    const widths = await Promise.all(args.items.map(
      async (item) => {
        const action = item?.action as ActionData;
        return await fn.strwidth(
          args.denops,
          (this.getAttr(args.denops, action)).rawText,
        );
      },
    ));
    let width = Math.max(...widths, this.#width);
    if (args.columnParams.limitLength) {
      width = Math.min(width, args.columnParams.limitLength);
    }
    this.#width = width;
    return Promise.resolve(width);
  }

  override getText(
    { denops, item, startCol }: GetTextArguments<Params>,
  ): GetTextResult {
    const action = item?.action as ActionData;
    const attr = this.getAttr(denops, action);
    const padding = " ".repeat(Math.max(this.#width - attr.rawText.length, 0));
    return {
      text: attr.rawText + padding,
      highlights: attr.highlights?.map((hl) => {
        return { ...hl, col: hl.col + startCol };
      }),
    };
  }

  override params(): Params {
    return { limitLength: 0 };
  }
}
