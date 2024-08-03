import type { FilterArguments } from "jsr:@shougo/ddu-vim@~5.0.0/filter";
import {
  BaseFilter,
  type DduItem,
  type Item,
} from "jsr:@shougo/ddu-vim@~5.0.0/types";

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
