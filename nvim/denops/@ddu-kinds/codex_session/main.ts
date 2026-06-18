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
  stats: SessionStats;
  tailMessages: Message[];
};

type Message = {
  role?: string;
  text: string;
};

type SessionStats = {
  lineCount: number;
  userCount: number;
  assistantCount: number;
  turnContextCount: number;
  compactedCount: number;
  toolCallCount: number;
  likelyTrivial: boolean;
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
      const action = item.action as ActionData;
      await openCodexSession(denops, action);
      return ActionFlags.None;
    },
    open: async ({ denops, items, actionParams }) => {
      const item = await ensureOnlyOneItem(denops, items);
      if (!item) {
        return ActionFlags.None;
      }
      const action = item.action as ActionData;
      const params = maybe(
        actionParams,
        is.ObjectOf({
          command: is.String,
        }),
      );
      await openCodexSession(denops, action, params?.command);
      return ActionFlags.None;
    },
    delete: async ({ denops, items }) => {
      if (items.length === 0) {
        return ActionFlags.None;
      }
      const targets = items.map((item) => item.action as ActionData);
      const label = targets.length === 1
        ? `${targets[0].baseName} (${targets[0].sessionId})`
        : `${targets.length} sessions`;
      const result = await denops.call(
        "confirm",
        `Delete ${label}?`,
        "&Yes\n&No",
        2,
      ) as number;
      if (result !== 1) {
        return ActionFlags.None;
      }
      for (const target of targets) {
        try {
          await Deno.remove(target.file);
        } catch (error) {
          await denops.call(
            "ddu#util#print_error",
            `failed to delete ${target.file}: ${String(error)}`,
            "ddu-kind-codex_session",
          );
        }
      }
      return ActionFlags.RefreshItems;
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

async function openCodexSession(
  denops: Denops,
  action: ActionData,
  command?: string,
) {
  const tmuxArgs = buildTmuxArgs(action, command);
  if (tmuxArgs && await runTmux(tmuxArgs)) {
    return;
  }

  const payload = await buildTerminalPayload(denops, action);
  const openCommand = buildOpenCommand(command, payload);
  await denops.cmd(openCommand);
}

function buildTmuxArgs(
  action: ActionData,
  command?: string,
): string[] | undefined {
  if (!Deno.env.get("TMUX")) {
    return;
  }

  const shellCommand = `codex resume ${shellQuote(action.sessionId)}`;
  const cwd = action.cwd && action.cwd.length > 0 ? action.cwd : ".";

  if (!command || command === "edit") {
    return ["split-window", "-c", cwd, shellCommand];
  }
  if (command === "vnew") {
    return ["split-window", "-h", "-c", cwd, shellCommand];
  }
  if (command === "new") {
    return ["split-window", "-v", "-c", cwd, shellCommand];
  }
  if (command === "tabedit" || command === "tabnew") {
    return ["new-window", "-c", cwd, shellCommand];
  }
}

async function runTmux(args: string[]): Promise<boolean> {
  try {
    const result = await new Deno.Command("tmux", {
      args,
      stdout: "null",
      stderr: "null",
    }).output();
    return result.code === 0;
  } catch {
    return false;
  }
}

async function buildTerminalPayload(
  denops: Denops,
  action: ActionData,
): Promise<string> {
  const sessionId = await fn.shellescape(denops, action.sessionId);
  if (!action.cwd) {
    return `terminal codex resume ${sessionId}`;
  }
  const cwd = await fn.shellescape(denops, action.cwd);
  return `terminal cd ${cwd} && codex resume ${sessionId}`;
}

function shellQuote(value: string): string {
  return `'${value.replaceAll("'", "'\\''")}'`;
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
  lines.push(
    `Stats: ${action.stats.lineCount} lines, ${action.stats.assistantCount} assistant, ${action.stats.userCount} user`,
  );
  if (action.stats.turnContextCount || action.stats.compactedCount) {
    lines.push(
      `Extra: ${action.stats.turnContextCount} turn_context, ${action.stats.compactedCount} compacted`,
    );
  }
  if (action.stats.toolCallCount) {
    lines.push(`Tools: ${action.stats.toolCallCount} response item tool calls`);
  }
  if (action.stats.likelyTrivial) {
    lines.push("Hint: likely trivial session");
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
