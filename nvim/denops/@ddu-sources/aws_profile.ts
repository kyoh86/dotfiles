import type {} from "https://deno.land/x/denops_std@v6.5.0/mod.ts";
import type { GatherArguments } from "https://deno.land/x/ddu_vim@v4.1.0/base/source.ts";
import {
  ActionFlags,
  BaseSource,
} from "https://deno.land/x/ddu_vim@v4.1.0/types.ts";
import type {
  Actions,
  Item,
} from "https://deno.land/x/ddu_vim@v3.10.3/types.ts";
import { echoerrCommand } from "https://denopkg.com/kyoh86/denops-util@master/command.ts";
import { TextLineStream } from "https://deno.land/std@0.224.0/streams/text_line_stream.ts";
import { environment } from "https://deno.land/x/denops_std@v6.5.0/variable/mod.ts";
import { is, maybe } from "https://deno.land/x/unknownutil@v3.18.1/mod.ts";

type ActionData = {
  name: string;
};

type Params = Record<PropertyKey, never>;

export class Source extends BaseSource<Params, ActionData> {
  kind = "word";
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
      console.log("hoge");
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
