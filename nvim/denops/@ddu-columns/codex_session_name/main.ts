import type { ItemHighlight } from "@shougo/ddu-vim/types";
import type { Denops } from "@denops/std";
import type { ActionData } from "../../@ddu-sources/codex_session/main.ts";
import { CodexSessionBaseColumn } from "../codex_session_base/main.ts";

export class Column extends CodexSessionBaseColumn {
  override async getAttr(
    _denops: Denops,
    { baseName }: ActionData,
  ): Promise<{
    rawText: string;
    highlights?: ItemHighlight[];
  }> {
    const rawText = baseName ? `${baseName} ` : "";
    if (!rawText) {
      return { rawText };
    }
    return {
      rawText,
      highlights: [{
        col: 0,
        width: rawText.length,
        hl_group: "Identifier",
        name: "dduColumnCodexSessionName0",
      }],
    };
  }

  override getBaseText(): string {
    return "";
  }
}
