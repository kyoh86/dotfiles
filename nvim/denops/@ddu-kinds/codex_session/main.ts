import type { Denops } from "@denops/std";
import { BaseKind } from "@shougo/ddu-vim/kind";
import {
  ActionFlags,
  type Actions,
  type DduItem,
  type Previewer,
} from "@shougo/ddu-vim/types";
import * as fn from "@denops/std/function";
import { is, maybe } from "@core/unknownutil";

export type ActionData = {
  sessionId: string;
  cwd: string;
  file: string;
  baseName: string;
  timeLabel: string;
  timestamp?: string;
  model?: string;
  tailMessages: Message[];
};

type Message = {
  role?: string;
  text: string;
};

type Params = Record<PropertyKey, never>;

async function ensureOnlyOneItem(denops: Denops, items: DduItem[]) {
  if (items.length != 1) {
    await denops.call(
      "ddu#util#print_error",
      "invalid action calling: it can accept only one item",
      "ddu-kind-codex_session",
    );
    return;
  }
  return items[0];
}

export class Kind extends BaseKind<Params> {
  override actions: Actions<Params> = {
    resume: async ({ denops, items }) => {
      const item = await ensureOnlyOneItem(denops, items);
      if (!item) {
        return ActionFlags.None;
      }
      const { sessionId } = item.action as ActionData;
      const escaped = await fn.shellescape(denops, sessionId);
      await denops.cmd(`terminal codex resume ${escaped}`);
      return ActionFlags.None;
    },
    open: async ({ denops, items, actionParams }) => {
      const item = await ensureOnlyOneItem(denops, items);
      if (!item) {
        return ActionFlags.None;
      }
      const { sessionId } = item.action as ActionData;
      const params = maybe(
        actionParams,
        is.ObjectOf({
          command: is.String,
        }),
      );
      const escaped = await fn.shellescape(denops, sessionId);
      const openCommand = buildOpenCommand(
        params?.command,
        `terminal codex resume ${escaped}`,
      );
      await denops.cmd(openCommand);
      return ActionFlags.None;
    },
  };

  override getPreviewer(
    { item }: { item: DduItem },
  ): Promise<Previewer | undefined> {
    const action = item.action as ActionData;
    return Promise.resolve({
      kind: "nofile",
      contents: formatPreviewLines(action),
      syntax: "markdown",
    });
  }

  params(): Params {
    return {};
  }
}

function buildOpenCommand(
  command: string | undefined,
  payload: string,
): string {
  if (!command || command === "edit") {
    return payload;
  }
  return `${command} | ${payload}`;
}

function formatPreviewLines(action: ActionData): string[] {
  const lines: string[] = [
    "-".repeat(20),
    `ID:    ${action.sessionId}`,
    `CWD:   ${action.cwd}`,
  ];
  if (action.timestamp) {
    lines.push(`Time:  ${formatTimestamp(action.timestamp)}`);
  }
  if (action.model) {
    lines.push(`Model: ${action.model}`);
  }
  lines.push("-".repeat(20));
  const messages = action.tailMessages.length > 0
    ? action.tailMessages
    : [{ text: "", role: undefined }];
  for (const message of messages) {
    lines.push(...formatMessageLines(message));
  }
  return lines;
}

function formatMessageLines(
  message: Message,
  options: { maxWidth?: number; maxLines?: number } = {},
): string[] {
  const maxLines = options.maxLines ?? 18;
  const sanitized = sanitizeMessage(message.text);
  const sourceLines = collapseEmptyLines(sanitized.split(/\r?\n/));

  if (
    sourceLines.length === 0 ||
    sourceLines.length === 1 && sourceLines[0].length == 0
  ) {
    return [];
  }

  const output: string[] = [""];
  if (message.role) {
    output.push(`${message.role.toLocaleUpperCase()}`);
    output.push("-".repeat(20));
  } else {
    output.push("-".repeat(20));
    output.push("");
  }
  const body = sourceLines.slice(0, maxLines);
  if (sourceLines.length > maxLines) {
    body[body.length - 1] += "...";
  }
  return output.concat(body);
}

function sanitizeMessage(text: string): string {
  return text
    .replace(/<environment_context>[\s\S]*?<\/environment_context>/g, "")
    .replace(/<INSTRUCTIONS>[\s\S]*?<\/INSTRUCTIONS>/g, "")
    .replace(/<\/?[^>]+>/g, "")
    .trim();
}

function formatTimestamp(timestamp?: string): string {
  if (!timestamp) {
    return "";
  }
  if (timestamp.length >= 19) {
    return timestamp.slice(0, 19).replace("T", " ");
  }
  return timestamp.replace("T", " ").replace("Z", "");
}

function collapseEmptyLines(lines: string[]): string[] {
  const result: string[] = [];
  let prevEmpty = false;
  for (const line of lines) {
    const trimmed = line.trim();
    const empty = trimmed.length === 0;
    if (empty) {
      if (prevEmpty) {
        continue;
      }
      result.push("");
    } else {
      result.push("  " + trimmed);
    }
    prevEmpty = empty;
  }
  return result;
}
