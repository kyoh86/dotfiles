import type {} from "@denops/std";
import * as fn from "@denops/std/function";
import * as vars from "@denops/std/variable";
import type { GatherArguments } from "@shougo/ddu-vim/source";
import { BaseSource } from "@shougo/ddu-vim/source";
import type { Item } from "@shougo/ddu-vim/types";
import { walk } from "@std/fs";
import { basename, join } from "@std/path";
import { is, maybe } from "@core/unknownutil";
import type { ActionData } from "../../@ddu-kinds/codex_session/main.ts";

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

type Message = {
  role?: string;
  text: string;
};

export class Source extends BaseSource<Params, ActionData> {
  override kind = "codex_session";

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
        timestamp: session.meta.timestamp,
        model: session.meta.model,
        tailMessages: session.tailMessages,
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
  { meta: SessionMeta; tailMessages: Message[] } | undefined
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
  const tailMessages = findTailMessages(lines, 10);
  return { meta, tailMessages };
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

function findTailMessages(lines: string[], n: number): Message[] {
  const msgs: Message[] = [];
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
      msgs.unshift({ role, text });
      if (msgs.length >= n) {
        break;
      }
    } catch {
      continue;
    }
  }
  return msgs;
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
