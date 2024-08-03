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
    const conds = await Promise.all(
      args.items.map(async (item) => {
        const action = item.action! as {
          bufNr: number;
        };
        const bufType = await getbufvar(args.denops, action.bufNr, "&buftype");
        return bufType !== "quickfix";
      }),
    );
    return args.items.filter((_, i) => conds[i]);
  }

  params(): Params {
    return defaultParams;
  }
}
