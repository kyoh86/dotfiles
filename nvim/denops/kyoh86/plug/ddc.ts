import {
  BaseConfig,
  UserSource,
} from "https://deno.land/x/ddc_vim@v4.1.0/types.ts";
import { ConfigArguments } from "https://deno.land/x/ddc_vim@v4.1.0/base/config.ts";

export class Config extends BaseConfig {
  override config(args: ConfigArguments): Promise<void> {
    const sources: UserSource[] = [
      { name: "nvim-lsp" },
      // "codeium",
      // "around",
      // "yank",
      // "file",
      // "mocword",
    ];

    args.contextBuilder.patchGlobal({
      ui: "pum",
      sources: sources,
      autoCompleteEvents: [],
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
          matchers: ["matcher_head", "matcher_prefix", "matcher_length"],
          sorters: ["sorter_rank"],
          converters: ["converter_remove_overlap"],
          timeout: 1000,
        },
        "nvim-lsp": {
          mark: "lsp",
          forceCompletionPattern: "\\.\\w*|::\\w*|->\\w*",
          dup: "force",
        },
      },
      postFilters: ["sorter_head"],
    });

    args.contextBuilder.patchFiletype("ddu-ff-filter", {
      sources: ["line", "buffer"],
      sourceOptions: {
        _: {
          keywordPattern: "[0-9a-zA-Z_:#-]*",
        },
      },
      specialBufferCompletion: true,
    });

    args.contextBuilder.patchFiletype("vim", {
      // Enable specialBufferCompletion for cmdwin.
      specialBufferCompletion: true,
    });

    return Promise.resolve();
  }
}
