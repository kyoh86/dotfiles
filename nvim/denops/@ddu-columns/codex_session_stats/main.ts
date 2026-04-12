import type { ItemHighlight } from "@shougo/ddu-vim/types";
import type { Denops } from "@denops/std";
import type { ActionData } from "../../@ddu-kinds/codex_session/main.ts";
import { CodexSessionBaseColumn } from "../codex_session_base/main.ts";

export class Column extends CodexSessionBaseColumn {
  override getAttr(
    _denops: Denops,
    { stats }: ActionData,
  ): {
    rawText: string;
    highlights?: ItemHighlight[];
  } {
    const rawText = `${stats.lineCount}L/${stats.assistantCount}A `;
    return {
      rawText,
      highlights: [{
        col: 0,
        width: rawText.length,
        hl_group: stats.likelyTrivial ? "WarningMsg" : "Number",
        name: "dduColumnCodexSessionStats0",
      }],
    };
  }
}
