import type {} from "@denops/std";
import type { GatherArguments } from "@shougo/ddu-vim/source";
import { ActionFlags, type Actions, type Item } from "@shougo/ddu-vim/types";
import { BaseSource } from "@shougo/ddu-vim/source";
import type { ActionData as WordActionData } from "@shougo/ddu-kind-word";
import { echoerrCommand } from "@kyoh86/denops-util/command";
import { TextLineStream } from "@std/streams";
import { environment } from "@denops/std/variable";
import { is, maybe } from "@core/unknownutil";

type ActionData = WordActionData & {
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
                write: (text) => {
                  controller.enqueue([
                    {
                      word: text,
                      action: {
                        name: text,
                        text,
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
