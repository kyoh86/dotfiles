import { environment } from "jsr:@denops/std@~7.4.0/variable";
import { ActionFlags, type Actions } from "jsr:@shougo/ddu-vim@~9.0.0/types";
import { BaseKind } from "jsr:@shougo/ddu-vim@~9.0.0/kind";
import { is, maybe } from "jsr:@core/unknownutil@~4.3.0";

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
