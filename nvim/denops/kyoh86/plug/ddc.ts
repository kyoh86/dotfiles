import type { UserSource } from "jsr:@shougo/ddc-vim@~9.3.0/types";
import { BaseConfig } from "jsr:@shougo/ddc-vim@~9.3.0/config";
import type { ConfigArguments } from "jsr:@shougo/ddc-vim@~9.3.0/config";

export class Config extends BaseConfig {
  override config(args: ConfigArguments): Promise<void> {
    const vsnip: UserSource = { name: "vsnip" };
    const lsp: UserSource = {
      name: "lsp",
      params: {
        snippetEngine: async (body: unknown) => {
          await args.denops.call("vsnip#anonymous", body);
        },
        enableResolveItem: true,
        enableAdditionalTextEdit: true,
      },
    };
    const nvim_lua: UserSource = { name: "nvim-lua" };

    args.contextBuilder.patchGlobal({
      ui: "pum",
      sources: [
        vsnip,
        lsp,
      ],
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
      },
    });

    args.contextBuilder.patchFiletype("ddu-ff-filter", {
      sources: [],
    });

    args.contextBuilder.patchFiletype("lua", {
      sources: [
        vsnip,
        lsp,
        nvim_lua,
      ],
      sourceOptions: {
        ["nvim-lua"]: {
          mark: "[nvim-lua]",
        },
      },
    });

    return Promise.resolve();
  }
}
