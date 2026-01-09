import type {} from "@denops/std";
import type { GatherArguments } from "@shougo/ddu-vim/source";
import type { Item } from "@shougo/ddu-vim/types";
import { BaseSource } from "@shougo/ddu-vim/source";
import type { ActionData } from "@shougo/ddu-kind-word";

type Params = Record<PropertyKey, never>;

export class Source extends BaseSource<Params, ActionData> {
  override kind = "word";
  override gather(
    {}: GatherArguments<Params>,
  ): ReadableStream<Item<ActionData>[]> {
    let timer: number | undefined = undefined;
    const cancel = () => {
      if (timer) clearInterval(timer);
    };
    return new ReadableStream<Item<ActionData>[]>({
      cancel,
      start: async (controller) => {
        return await new Promise((resolve) => {
          let i = 0;
          timer = setInterval(() => {
            controller.enqueue([
              {
                word: `foo-${i}`,
                action: { text: `foo-${i}` },
              },
            ]);
            i++;
            if (i > 5) {
              resolve(0);
              cancel();
            }
          }, 1000);
        }).finally(() => {
          controller.close();
        });
      },
    });
  }

  override params(): Params {
    return {};
  }
}
