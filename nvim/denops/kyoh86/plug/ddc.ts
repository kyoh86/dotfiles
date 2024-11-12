import type { UserSource } from "jsr:@shougo/ddc-vim@~8.1.0/types";
import { BaseConfig } from "jsr:@shougo/ddc-vim@~8.1.0/config";
import type { ConfigArguments } from "jsr:@shougo/ddc-vim@~8.1.0/config";

export class Config extends BaseConfig {
  override config(args: ConfigArguments): Promise<void> {
    const sources: UserSource[] = [
      { name: "vsnip" },
      {
        name: "lsp",
        params: {
          snippetEngine: async (body: unknown) => {
            await args.denops.call("vsnip#anonymous", body);
          },
          enableResolveItem: true,
          enableAdditionalTextEdit: true,
        },
      },
      { name: "nvim-lua" },
    ];

    args.contextBuilder.patchGlobal({
      ui: "pum",
      sources: sources,
      sourceOptions: {
        _: {
          ignoreCase: true,
          timeout: 500,

          maxAutoCompleteLength: 0,
          matchers: ["matcher_head", "matcher_prefix", "matcher_length"],
          sorters: ["sorter_rank"],
          converters: ["converter_remove_overlap"],
        },
        lsp: {
          mark: "[lsp]",
          forceCompletionPattern: "\\.\\w*|::\\w*|->\\w*",
        },
        vsnip: {
          mark: "[vsnip]",
        },
        ["nvim-lua"]: {
          mark: "[nvim-lua]",
        },
      },
      // postFilters: ["sorter_head"],
    });

    args.contextBuilder.patchFiletype("ddu-ff-filter", {
      sources: [],
    });

    return Promise.resolve();
  }
}
