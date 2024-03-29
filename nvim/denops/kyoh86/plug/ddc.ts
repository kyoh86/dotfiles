import {
  BaseConfig,
  UserSource,
} from "https://deno.land/x/ddc_vim@v4.3.1/types.ts";
import { ConfigArguments } from "https://deno.land/x/ddc_vim@v4.3.1/base/config.ts";

export class Config extends BaseConfig {
  override config(args: ConfigArguments): Promise<void> {
    const sources: UserSource[] = [
      { name: "copilot" },
      { name: "ollama" },
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
      cmdlineSources: {
        ":": ["cmdline", "cmdline-history"],
        "@": ["input", "cmdline-history"],
        ">": ["input", "cmdline-history"],
        "/": ["line"],
        "?": ["line"],
        "-": ["line"],
        "=": ["input"],
      },
      sourceOptions: {
        _: {
          ignoreCase: true,
          timeout: 500,

          maxAutoCompleteLength: 0,
          matchers: ["matcher_head", "matcher_prefix", "matcher_length"],
          sorters: ["sorter_rank"],
          converters: ["converter_remove_overlap"],
        },
        copilot: {
          mark: "[copilot]",
          isVolatile: true,
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

    args.contextBuilder.patchFiletype("vim", {
      // Enable specialBufferCompletion for cmdwin.
      specialBufferCompletion: true,
    });

    return Promise.resolve();
  }
}
