import { FilterArguments } from "https://deno.land/x/ddu_vim@v4.1.0/base/filter.ts";
import { getbufvar } from "https://deno.land/x/denops_std@v6.5.0/function/buffer.ts";
import {
  BaseFilter,
  DduItem,
} from "https://deno.land/x/ddu_vim@v4.1.0/types.ts";

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
