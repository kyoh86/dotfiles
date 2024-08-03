import type { FilterArguments } from "jsr:@shougo/ddu-vim@~5.0.0/filter";
import { getbufvar } from "jsr:@denops/std@~7.0.1/function";
import { BaseFilter, type DduItem } from "jsr:@shougo/ddu-vim@~5.0.0/types";

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
