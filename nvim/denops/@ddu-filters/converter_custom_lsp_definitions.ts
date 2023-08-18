import { FilterArguments } from "https://deno.land/x/ddu_vim@v3.4.0/base/filter.ts";
import {
  BaseFilter,
  DduItem,
  Item,
} from "https://deno.land/x/ddu_vim@v3.4.0/types.ts";

type Params = Record<PropertyKey, never>;

type ActionData = {
  context?: {
    method?: string;
  };
};

const MethodLabel: Record<string, string> = {
  "textDocument/definition": "Def",
  "textDocument/typeDefinition": "Type",
  "textDocument/declaration": "Decl",
  "textDocument/implementation": "Impl",
};

export class Filter extends BaseFilter<Params> {
  filter(
    { items }: FilterArguments<Params>,
  ): Promise<DduItem[]> {
    return Promise.resolve(
      items.map((item, index) => {
        const typedItem = item as Item<ActionData>;
        const method = typedItem?.action?.context?.method;
        if (!method) {
          return item;
        }
        const label = MethodLabel[method];
        if (!label) {
          return item;
        }
        item.display = `${label.toUpperCase()}${
          " ".repeat(5 - label.length)
        }${(item.display || item.word)}`;
        item.highlights = [
          {
            name: `ddu-lsp-definition-method-${index}`,
            col: 1,
            width: 4,
            hl_group: `DduLspDefinitionMethod${label}`,
          },
        ];
        return item;
      }),
    );
  }
  params(): Params {
    return {};
  }
}
