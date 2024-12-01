import type {} from "jsr:@denops/std@~7.4.0";
import type { GatherArguments } from "jsr:@shougo/ddu-vim@~7.0.0/source";
import {
  ActionFlags,
  type Actions,
  type Item,
} from "jsr:@shougo/ddu-vim@~7.0.0/types";
import { BaseSource } from "jsr:@shougo/ddu-vim@~7.0.0/source";
import { echoerrCommand } from "jsr:@kyoh86/denops-util@~0.1.0/command";
import { TextLineStream } from "jsr:@std/streams@~1.0.0";
import { environment } from "jsr:@denops/std@~7.4.0/variable";
import { is, maybe } from "jsr:@core/unknownutil@~4.3.0";

type ActionData = {
  name: string;
};

type Params = Record<PropertyKey, never>;

export class Source extends BaseSource<Params, ActionData> {
  override kind = "word";
  override gather({
    denops,
  }: GatherArguments<Params>): ReadableStream<Item<ActionData>[]> {
    return new ReadableStream<Item<ActionData>[]>({
      start: async (controller) => {
        const { wait, pipeOut, finalize } = echoerrCommand(denops, "aws", {
          args: ["configure", "list-profiles"],
        });
        await Promise.all([
          pipeOut
            .pipeThrough(new TextLineStream())
            .pipeTo(
              new WritableStream({
                write: (chunk) => {
                  controller.enqueue([
                    {
                      word: chunk,
                      action: {
                        name: chunk,
                      },
                    },
                  ]);
                },
              }),
            ),
          wait,
        ])
          .finally(async () => {
            await finalize();
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
