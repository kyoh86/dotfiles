import type {} from "jsr:@denops/std@~7.4.0";
import type { GatherArguments } from "jsr:@shougo/ddu-vim@~9.5.0/source";
import {
  ActionFlags,
  type Actions,
  type Item,
} from "jsr:@shougo/ddu-vim@~9.5.0/types";
import { BaseSource } from "jsr:@shougo/ddu-vim@~9.5.0/source";
import type { ActionData } from "jsr:@shougo/ddu-kind-word@~0.4.1";
import { environment } from "jsr:@denops/std@~7.4.0/variable";
import { is, maybe } from "jsr:@core/unknownutil@~4.3.0";

type Params = Record<PropertyKey, never>;

export class Source extends BaseSource<Params, ActionData> {
  override kind = "word";
  override gather(
    {}: GatherArguments<Params>,
  ): ReadableStream<Item<ActionData>[]> {
    return new ReadableStream<Item<ActionData>[]>({
      start: async (controller) => {
        return await new Promise((resolve) => {
          let i = 0;
          const id = setInterval(() => {
            try {
              controller.enqueue([
                {
                  word: `foo-${i}`,
                  action: { text: `foo-${i}` },
                },
              ]);
              i++;
              if (i > 5) {
                resolve(0);
                clearInterval(id);
              }
            } catch {
              resolve(1);
              clearInterval(id);
            }
          }, 1000);
        }).finally(() => {
          controller.close();
        });
      },
    });
  }

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

  override params(): Params {
    return {};
  }
}
