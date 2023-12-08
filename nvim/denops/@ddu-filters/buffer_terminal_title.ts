import { FilterArguments } from "https://deno.land/x/ddu_vim@v3.4.5/base/filter.ts";
import { getbufvar } from "https://deno.land/x/denops_std@v5.0.2/function/buffer.ts";
import {
  BaseFilter,
  DduItem,
} from "https://deno.land/x/ddu_vim@v3.4.5/types.ts";

const defaultParams = {
  highlightAdded: "diffAdded",
  highlightRemoved: "diffRemoved",
};

type Params = typeof defaultParams;

export class Filter extends BaseFilter<Params> {
  async filter(args: FilterArguments<Params>): Promise<DduItem[]> {
    const newItems = await Promise.all(args.items.map(async (item) => {
      const action = item.action! as {
        bufNr: number;
        isTerminal: boolean;
      };
      if (!action.isTerminal) {
        return item;
      }
      const title = await getbufvar(args.denops, action.bufNr, "term_title");
      if (title !== "") {
        item.word = item.word.replace(/term:\/\/.*/, `term://${title}`);
      }
      return item;
    }));
    return Promise.resolve(newItems as DduItem[]);
  }

  params(): Params {
    return defaultParams;
  }
}
