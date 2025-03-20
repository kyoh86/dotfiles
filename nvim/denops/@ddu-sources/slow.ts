import type {} from "jsr:@denops/std@~7.5.0";
import type { GatherArguments } from "jsr:@shougo/ddu-vim@~10.3.0/source";
import type { Item } from "jsr:@shougo/ddu-vim@~10.3.0/types";
import { BaseSource } from "jsr:@shougo/ddu-vim@~10.3.0/source";
import type { ActionData } from "jsr:@shougo/ddu-kind-word@~0.4.1";

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
