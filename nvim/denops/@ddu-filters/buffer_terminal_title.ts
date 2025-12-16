import type { FilterArguments } from "@shougo/ddu-vim/filter";
import { getbufvar } from "@denops/std/function";
import type { DduItem } from "@shougo/ddu-vim/types";
import { BaseFilter } from "@shougo/ddu-vim/filter";

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
