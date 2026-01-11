import type {} from "@denops/std";
import * as fn from "@denops/std/function";
import * as vars from "@denops/std/variable";
import type { GatherArguments } from "@shougo/ddu-vim/source";
import { BaseSource } from "@shougo/ddu-vim/source";
import { ActionFlags, type Actions, type Item } from "@shougo/ddu-vim/types";
import type { ActionData as WordActionData } from "@shougo/ddu-kind-word";
import { walk } from "@std/fs";
import { basename, join } from "@std/path";
import { is, maybe } from "@core/unknownutil";

export type ActionData = WordActionData & {
  sessionId: string;
  cwd: string;
  file: string;
  baseName: string;
  timeLabel: string;
};

type Params = {
  cwd?: string;
};

type SessionMeta = {
  id: string;
  cwd: string;
  timestamp?: string;
  originator?: string;
  model?: string;
  model_provider?: string;
  cli_version?: string;
  source?: string;
};

type LastMessage = {
  role?: string;
  text?: string;
};

export class Source extends BaseSource<Params, ActionData> {
  override kind = "word";

  override gather(
    { denops, sourceParams }: GatherArguments<Params>,
  ): ReadableStream<Item<ActionData>[]> {
    return new ReadableStream<Item<ActionData>[]>({
      start: async (controller) => {
        const targetCwd = await resolveTargetCwd(denops, sourceParams);
        const codexHome = await resolveCodexHome(denops);
        const sessionsDir = join(codexHome, "sessions");
        const items = await collectSessions(sessionsDir, targetCwd);
        controller.enqueue(items);
        controller.close();
      },
    });
  }

  override actions: Actions<Params> = {
    resume: async (args) => {
      if (args.items.length != 1) {
        console.error(`multiple items are not supported to call "resume"`);
        return ActionFlags.None;
      }
      const action = maybe(
        args.items[0].action,
        is.ObjectOf({
          sessionId: is.String,
        }),
      );
      if (!action || !action.sessionId) {
        console.error("invalid selected item (having no sessionId)");
        return ActionFlags.None;
      }
      const escaped = await fn.shellescape(args.denops, action.sessionId);
      await args.denops.cmd(`terminal codex resume ${escaped}`);
      return ActionFlags.None;
    },
    open: async (args) => {
      if (args.items.length != 1) {
        console.error(`multiple items are not supported to call "open"`);
        return ActionFlags.None;
      }
      const action = maybe(
        args.items[0].action,
        is.ObjectOf({
          sessionId: is.String,
        }),
      );
      if (!action || !action.sessionId) {
        console.error("invalid selected item (having no sessionId)");
        return ActionFlags.None;
      }
      const params = maybe(
        args.actionParams,
        is.ObjectOf({
          command: is.String,
        }),
      );
      const escaped = await fn.shellescape(args.denops, action.sessionId);
      const openCommand = buildOpenCommand(
        params?.command,
        `terminal codex resume ${escaped}`,
      );
      await args.denops.cmd(openCommand);
      return ActionFlags.None;
    },
  };

  override params(): Params {
    return {
      cwd: "",
    };
  }
}

async function resolveTargetCwd(
  denops: GatherArguments<Params>["denops"],
  params: Params,
): Promise<string> {
  const raw = params.cwd?.trim();
  const cwd = raw && raw.length > 0 ? raw : await fn.getcwd(denops);
  const normalized = await fn.fnamemodify(denops, cwd, ":p");
  return stripTrailingSlash(normalized);
}

async function resolveCodexHome(
  denops: GatherArguments<Params>["denops"],
): Promise<string> {
  const codexHomeValue = await vars.e.get(denops, "CODEX_HOME", "");
  const codexHome = maybe(codexHomeValue, is.String);
  if (codexHome && codexHome.length > 0) {
    return stripTrailingSlash(codexHome);
  }
  const fallbackValue = await fn.expand(denops, "~/.codex");
  const fallback = maybe(fallbackValue, is.String) ?? "~/.codex";
  return stripTrailingSlash(fallback);
}

async function collectSessions(
  sessionsDir: string,
  targetCwd: string,
): Promise<Item<ActionData>[]> {
  const files = await collectSessionFiles(sessionsDir);
  const items: Item<ActionData>[] = [];
  for (const file of files) {
    const session = await readSession(file);
    if (!session) {
      continue;
    }
    const sessionCwd = stripTrailingSlash(session.meta.cwd);
    if (!isUnder(sessionCwd, targetCwd)) {
      continue;
    }
    const baseName = formatBaseName(sessionCwd);
    const timeLabel = formatTimeLabel(session.meta.timestamp);
    items.push({
      word: `${baseName} ${session.meta.cwd}`.trim(),
      action: {
        sessionId: session.meta.id,
        cwd: session.meta.cwd,
        file,
        baseName,
        timeLabel,
        info: formatInfo(session.meta, session.lastMessage),
        text: session.meta.id,
      },
    });
  }
  return items;
}

async function collectSessionFiles(sessionsDir: string): Promise<string[]> {
  const files: string[] = [];
  try {
    for await (
      const entry of walk(sessionsDir, {
        includeDirs: false,
        includeFiles: true,
        exts: ["jsonl"],
      })
    ) {
      files.push(entry.path);
    }
  } catch {
    return [];
  }
  return files.sort().reverse();
}

async function readSession(file: string): Promise<
  { meta: SessionMeta; lastMessage?: LastMessage } | undefined
> {
  let content: string;
  try {
    content = await Deno.readTextFile(file);
  } catch {
    return;
  }
  const lines = content.split(/\r?\n/).filter((line) => line.length > 0);
  if (lines.length === 0) {
    return;
  }
  const meta = parseSessionMeta(lines[0]);
  if (!meta) {
    return;
  }
  const lastMessage = findLastMessage(lines);
  return { meta, lastMessage };
}

function parseSessionMeta(line: string): SessionMeta | undefined {
  try {
    const data = JSON.parse(line) as {
      type?: string;
      payload?: Record<string, unknown>;
    };
    if (data?.type !== "session_meta") {
      return;
    }
    const payload = data.payload ?? {};
    const id = payload.id;
    const cwd = payload.cwd;
    if (typeof id !== "string" || typeof cwd !== "string") {
      return;
    }
    return {
      id,
      cwd,
      timestamp: typeof payload.timestamp === "string"
        ? payload.timestamp
        : undefined,
      originator: typeof payload.originator === "string"
        ? payload.originator
        : undefined,
      model: typeof payload.model === "string" ? payload.model : undefined,
      model_provider: typeof payload.model_provider === "string"
        ? payload.model_provider
        : undefined,
      cli_version: typeof payload.cli_version === "string"
        ? payload.cli_version
        : undefined,
      source: typeof payload.source === "string" ? payload.source : undefined,
    };
  } catch {
    return;
  }
}

function findLastMessage(lines: string[]): LastMessage | undefined {
  for (let i = lines.length - 1; i >= 0; i -= 1) {
    const line = lines[i];
    try {
      const data = JSON.parse(line) as {
        type?: string;
        payload?: Record<string, unknown>;
      };
      if (data?.type !== "response_item") {
        continue;
      }
      const payload = data.payload ?? {};
      if (payload.type !== "message") {
        continue;
      }
      const role = typeof payload.role === "string" ? payload.role : undefined;
      const text = extractMessageText(payload.content);
      if (!text) {
        continue;
      }
      return { role, text };
    } catch {
      continue;
    }
  }
  return;
}

function extractMessageText(
  content: unknown,
): string | undefined {
  if (!Array.isArray(content)) {
    return;
  }
  const texts: string[] = [];
  for (const part of content) {
    if (typeof part === "string") {
      texts.push(part);
      continue;
    }
    if (typeof part === "object" && part) {
      const text = (part as { text?: unknown }).text;
      if (typeof text === "string") {
        texts.push(text);
      }
    }
  }
  if (texts.length === 0) {
    return;
  }
  return texts.join("");
}

function formatInfo(meta: SessionMeta, lastMessage?: LastMessage): string {
  const lines: string[] = [];
  lines.push(`ID        ${meta.id}`);
  lines.push(`CWD       ${meta.cwd}`);
  if (meta.timestamp) {
    lines.push(`Time      ${formatTimestamp(meta.timestamp)}`);
  }
  if (meta.model) {
    lines.push(`Model     ${meta.model}`);
  }
  lines.push("");
  const messageLines = formatMessageLines(lastMessage?.text ?? "");
  lines.push(...messageLines);
  return lines.join("\n");
}

function formatMessageLines(
  text: string,
  options: { maxWidth?: number; maxLines?: number } = {},
): string[] {
  const maxWidth = options.maxWidth ?? 96;
  const maxLines = options.maxLines ?? 18;
  const sanitized = sanitizeMessage(text);
  const sourceLines = sanitized.split(/\r?\n/);
  const output: string[] = [];
  for (const line of sourceLines) {
    if (output.length >= maxLines) {
      break;
    }
    const trimmed = line.trimEnd();
    if (!trimmed) {
      output.push("");
      continue;
    }
    for (const wrapped of wrapLine(trimmed, maxWidth)) {
      output.push(wrapped);
      if (output.length >= maxLines) {
        break;
      }
    }
  }
  if (output.length >= maxLines && sourceLines.length > 0) {
    output[output.length - 1] = output[output.length - 1] + "…";
  }
  return output;
}

function sanitizeMessage(text: string): string {
  return text
    .replace(/<environment_context>[\s\S]*?<\/environment_context>/g, "")
    .replace(/<INSTRUCTIONS>[\s\S]*?<\/INSTRUCTIONS>/g, "")
    .replace(/<\/?[^>]+>/g, "")
    .trim();
}

function wrapLine(line: string, maxWidth: number): string[] {
  if (line.length <= maxWidth) {
    return [line];
  }
  const parts: string[] = [];
  let rest = line;
  while (rest.length > maxWidth) {
    let cut = rest.lastIndexOf(" ", maxWidth);
    if (cut <= 0) {
      cut = maxWidth;
    }
    parts.push(rest.slice(0, cut).trimEnd());
    rest = rest.slice(cut).trimStart();
  }
  if (rest.length > 0) {
    parts.push(rest);
  }
  return parts;
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

function formatTimeLabel(timestamp?: string): string {
  if (!timestamp) {
    return "";
  }
  const parsed = Date.parse(timestamp);
  if (!Number.isFinite(parsed)) {
    return "";
  }
  const now = Date.now();
  const diffMs = now - parsed;
  if (diffMs >= 0 && diffMs < 6 * 60 * 60 * 1000) {
    const minutes = Math.max(Math.floor(diffMs / 60000), 0);
    if (minutes < 1) {
      return "now";
    }
    if (minutes < 60) {
      return `${minutes}m ago`;
    }
    const hours = Math.floor(minutes / 60);
    return `${hours}h ago`;
  }
  return formatMonthDayTime(new Date(parsed));
}

function formatMonthDayTime(date: Date): string {
  const month = pad2(date.getMonth() + 1);
  const day = pad2(date.getDate());
  const hour = pad2(date.getHours());
  const minute = pad2(date.getMinutes());
  return `${month}/${day} ${hour}:${minute}`;
}

function pad2(value: number): string {
  return String(value).padStart(2, "0");
}

function formatBaseName(path: string): string {
  const name = basename(path);
  if (name && name !== "/") {
    return name;
  }
  const trimmed = stripTrailingSlash(path);
  return basename(trimmed) || trimmed;
}

function stripTrailingSlash(path: string): string {
  return path.replace(/\/+$/, "");
}

function isUnder(path: string, base: string): boolean {
  if (path === base) {
    return true;
  }
  return path.startsWith(`${base}/`);
}

function buildOpenCommand(command: string | undefined, payload: string): string {
  if (!command || command === "edit") {
    return payload;
  }
  return `${command} | ${payload}`;
}
