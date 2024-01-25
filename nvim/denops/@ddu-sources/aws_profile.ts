import type {} from "https://deno.land/x/denops_std@v5.3.0/mod.ts";
import type { GatherArguments } from "https://deno.land/x/ddu_vim@v3.10.0/base/source.ts";
import {
  ActionFlags,
  BaseSource,
} from "https://deno.land/x/ddu_vim@v3.10.0/types.ts";
import type {
  Actions,
  Item,
} from "https://deno.land/x/ddu_vim@v3.10.0/types.ts";
import { echoerrCommand } from "https://denopkg.com/kyoh86/denops-util@v0.0.6/command.ts";
import { TextLineStream } from "https://deno.land/std@0.184.0/streams/text_line_stream.ts";
import { environment } from "https://deno.land/x/denops_std@v5.0.1/variable/mod.ts";
import { is, maybe } from "https://deno.land/x/unknownutil@v3.14.1/mod.ts";

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
        const { waitErr, pipeOut, finalize } = echoerrCommand(denops, "aws", {
          args: ["configure", "list-profiles"],
        });
        await pipeOut
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
          )
          .finally(async () => {
            await waitErr;
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
