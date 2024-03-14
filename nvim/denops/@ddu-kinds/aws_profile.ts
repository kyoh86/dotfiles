import {
  ActionFlags,
  BaseKind,
} from "https://deno.land/x/ddu_vim@v3.10.3/types.ts";
import { environment } from "https://deno.land/x/denops_std@v6.4.0/variable/mod.ts";
import type {
  Actions,
} from "https://deno.land/x/ddu_vim@v3.10.3/types.ts";
import { is, maybe } from "https://deno.land/x/unknownutil@v3.17.0/mod.ts";

type Params = Record<PropertyKey, never>;

export class Kind extends BaseKind<Params> {
  override actions: Actions<Params> = {
    setenv: async (args) => {
      if (args.items.length != 1) {
        console.error(`multiple items are not supported to call "setenv"`);
        return ActionFlags.None;
      }
      const action = maybe(
        args.items[0].action,
        is.ObjectOf({
          name: is.String,
        }),
      );
      console.log("hoge")
      if (!action || !action.name) {
        console.error("invalid selected item (having no name)");
        return ActionFlags.None;
      }
      await environment.set(args.denops, "AWS_PROFILE", action.name);
      return ActionFlags.None;
    },
  };
  params(): Params {
    return {};
  }
}
