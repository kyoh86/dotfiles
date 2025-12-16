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
