import { FilterArguments } from "https://deno.land/x/ddu_vim@v3.4.5/base/filter.ts";
import { buffers } from "https://deno.land/x/denops_std@v5.0.2/variable/mod.ts";
import { ensure } from "https://deno.land/x/denops_std@v5.0.2/buffer/mod.ts";
import {
  BaseFilter,
  DduItem,
  Item,
  ItemHighlight,
} from "https://deno.land/x/ddu_vim@v3.4.5/types.ts";

type ActionData = {
  bufNr: number;
  isTerminal: boolean;
};

const defaultParams = {
  highlightAdded: "diffAdded",
  highlightRemoved: "diffRemoved",
};

type Params = typeof defaultParams;

export class Filter extends BaseFilter<Params> {
  async filter(args: FilterArguments<Params>): Promise<DduItem[]> {
    const items = args.items as Item<ActionData>[];
    const newItems = await Promise.all(items.map(async (item) => {
      if (!item.action?.isTerminal) {
        return item;
      }

      await ensure(args.denops, item.action.bufNr, async () => {
        const title = await buffers.get(args.denops, "term_title", "");
        if (title !== "") {
          item.word = item.word.replace(/term:\/\/.*/, `term://${title}`);
        }
      });
      return item;
    }));
    return Promise.resolve(newItems as DduItem[]);
  }

  params(): Params {
    return defaultParams;
  }
}
