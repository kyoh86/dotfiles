import * as vars from "@denops/std/variable";
import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { fromFileUrl } from "@std/path";
const DEFAULT_PROXY_URL = "http://127.0.0.1:37125";
const SYSTEMD_SERVICE_NAME = "nvim-proxy.service";
const LAUNCHD_LABEL = "dev.kyoh86.nvim-proxy";
const REGISTER_RETRY_LIMIT = 5;
const REGISTER_BACKOFF_BASE_MS = 200;

export async function main(denops: Denops): Promise<void> {
  denops.dispatcher = {
    install: async () => {
      await installService(denops);
    },
    start: async () => {
      await startService();
    },
    restart: async () => {
      await restartService();
    },
    ensure: async () => {
      await ensureProxyServer(denops);
    },
    status: async () => {
      return await collectStatus();
    },
    log: async () => {
      return await collectLog();
    },
  };

  const autostart = await vars.g.get(denops, "nvim_proxy_autostart", 1);
  if (autostart !== 0) {
    await ensureProxyServer(denops);
  }

  const pid = await fn.getpid(denops);

  await vars.e.set(denops, "NVIM_PROXY_URL", DEFAULT_PROXY_URL);
  await vars.e.set(denops, "NVIM_PID", String(pid));

  if (Deno.env.get("TMUX")) {
    await Promise.all([
      setTmuxEnv("NVIM_PROXY_URL", DEFAULT_PROXY_URL),
      setTmuxEnv("NVIM_PID", String(pid)),
    ]);
  }

  await startLocalServer(denops, pid);
}

async function setTmuxEnv(key: string, value: string) {
  const command = new Deno.Command("tmux", {
    args: ["set-environment", key, value],
  });
  const { code, stdout, stderr } = await command.output();
  if (code !== 0) {
    console.log(new TextDecoder().decode(stdout));
    console.log(new TextDecoder().decode(stderr));
  }
}

async function startLocalServer(denops: Denops, pid: number) {
  const { finished } = Deno.serve({
    hostname: "127.0.0.1",
    port: 0,
    handler: async (req) => {
      const { pathname } = new URL(req.url);
      if (pathname === "/health") {
        return json({ status: "ok" });
      }
      if (pathname === "/env") {
        return await handleEnvRequest(denops, req);
      }
      if (pathname === "/notify") {
        return await handleNotifyRequest(denops, req);
      }
      if (pathname === "/setreg") {
        return await handleSetregRequest(denops, req);
      }
      if (pathname === "/getreg") {
        return await handleGetregRequest(denops, req);
      }
      if (pathname === "/open") {
        return await handleOpenRequest(denops, req);
      }
      if (pathname === "/scratch") {
        return await handleScratchRequest(denops, req);
      }
      if (pathname === "/focus-edge") {
        return await handleFocusEdgeRequest(denops, req);
      }
      return json({ error: "Not found" }, 404);
    },
    onListen: async ({ port }) => {
      await registerLocalRoutesToProxy(denops, { pid, port });
    },
  });
  await finished;
}

async function handleEnvRequest(denops: Denops, req: Request) {
  const names = await readEnvNames(req);
  if (names === undefined) {
    return json({ error: "Invalid body" }, 400);
  }
  const env: Record<string, string> = {};
  for (const name of names) {
    const value = await vars.e.get(denops, name, "");
    if (typeof value === "string" && value.length > 0) {
      env[name] = value;
    }
  }
  return json({ env });
}

async function handleNotifyRequest(denops: Denops, req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return json({ error: "Invalid body" }, 400);
  }
  const event = readStringField(body, "event");
  if (!event || !isSafeUserEvent(event)) {
    return json({ error: "Invalid event" }, 400);
  }
  await denops.cmd(`doautocmd <nomodeline> User ${event}`);
  return json({ ok: true });
}

async function handleSetregRequest(denops: Denops, req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return json({ error: "Invalid body" }, 400);
  }
  const register = readStringField(body, "register");
  const value = readStringField(body, "value");
  if (!register || !isSafeRegisterName(register)) {
    return json({ error: "Invalid register" }, 400);
  }
  if (value === undefined) {
    return json({ error: "Invalid value" }, 400);
  }
  await denops.call("setreg", register, value, "v");
  return json({ ok: true });
}

async function handleGetregRequest(denops: Denops, req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return json({ error: "Invalid body" }, 400);
  }
  const register = readStringField(body, "register");
  if (!register || !isSafeRegisterName(register)) {
    return json({ error: "Invalid register" }, 400);
  }
  const value = await denops.call("getreg", register) as string;
  return json({ value });
}

async function handleOpenRequest(denops: Denops, req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return json({ error: "Invalid body" }, 400);
  }
  const kind = readStringField(body, "kind");
  const target = readStringField(body, "target") ?? "";
  if (!kind || !isSafeOpenKind(kind)) {
    return json({ error: "Invalid open request" }, 400);
  }
  const line = readStringField(body, "line") ?? "";
  const cursorCol = readNumberField(body, "cursor_col") ?? 0;

  if (kind === "extra") {
    if (target !== "") {
      await denops.call(
        "luaeval",
        "require('kyoh86.conf.open_extra').open_extra(_A.target)",
        { target },
      );
      return json({ ok: true });
    }
    await denops.call(
      "luaeval",
      "require('kyoh86.conf.open_extra').open_extra_at(_A.line, _A.cursor_col)",
      { line, cursor_col: cursorCol },
    );
    return json({ ok: true });
  }

  const split = readStringField(body, "split") ?? "none";
  const cwd = readStringField(body, "cwd") ?? "";
  if (!isSafeOpenSplit(split)) {
    return json({ error: "Invalid split" }, 400);
  }
  if (target !== "") {
    await denops.call(
      "luaeval",
      "require('kyoh86.conf.open_buffer').open_buffer(_A.target, _A.opener, _A.cwd)",
      { target, opener: { reuse: true, split }, cwd },
    );
  } else {
    await denops.call(
      "luaeval",
      "require('kyoh86.conf.open_buffer').open_buffer_at(_A.line, _A.cursor_col, _A.opener, _A.cwd)",
      { line, cursor_col: cursorCol, opener: { reuse: true, split }, cwd },
    );
  }
  return json({ ok: true });
}

async function handleScratchRequest(denops: Denops, req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return json({ error: "Invalid body" }, 400);
  }
  const text = readStringField(body, "text");
  if (text === undefined) {
    return json({ error: "Invalid scratch request" }, 400);
  }
  await denops.call(
    "luaeval",
    "require('kyoh86.conf.tmux_capture').open(_A)",
    {
      kind: readStringField(body, "kind") ?? "",
      pane: readStringField(body, "pane") ?? "",
      cwd: readStringField(body, "cwd") ?? "",
      title: readStringField(body, "title") ?? "",
      text,
    },
  );
  return json({ ok: true });
}

async function handleFocusEdgeRequest(denops: Denops, req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return json({ error: "Invalid body" }, 400);
  }
  const direction = readStringField(body, "direction");
  if (!direction || !isSafeDirection(direction)) {
    return json({ error: "Invalid direction" }, 400);
  }
  await denops.call(
    "luaeval",
    "require('kyoh86.lib.tmux').focus_edge(_A.direction)",
    { direction },
  );
  return json({ ok: true });
}

function readStringField(body: object, key: string) {
  if (!(key in body)) {
    return undefined;
  }
  const value = (body as Record<string, unknown>)[key];
  return typeof value === "string" ? value : undefined;
}

function readNumberField(body: object, key: string) {
  if (!(key in body)) {
    return undefined;
  }
  const value = (body as Record<string, unknown>)[key];
  return typeof value === "number" && Number.isFinite(value)
    ? value
    : undefined;
}

async function readEnvNames(req: Request) {
  const url = new URL(req.url);
  const raw = [
    ...url.searchParams.getAll("name"),
    ...url.searchParams.getAll("names").flatMap((value) => value.split(",")),
  ];
  if (req.method !== "GET" && req.method !== "HEAD") {
    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object" || !("names" in body)) {
      return undefined;
    }
    if (!Array.isArray(body.names)) {
      return undefined;
    }
    raw.push(...body.names);
  }
  const names = raw
    .filter((name): name is string => typeof name === "string")
    .map((name) => name.trim())
    .filter(isSafeEnvName);
  return Array.from(new Set(names));
}

function isSafeEnvName(name: string) {
  return /^[A-Za-z_][A-Za-z0-9_]*$/.test(name);
}

function isSafeUserEvent(name: string) {
  return /^[A-Za-z0-9_:+/=-]+$/.test(name);
}

function isSafeRegisterName(name: string) {
  return /^["*+0-9A-Za-z._:%#/@-]$/.test(name);
}

function isSafeOpenKind(name: string) {
  return name === "extra" || name === "file";
}

function isSafeOpenSplit(name: string) {
  return [
    "none",
    "left",
    "right",
    "rightmost",
    "leftmost",
    "above",
    "below",
    "top",
    "bottom",
    "tab",
  ].includes(name);
}

function isSafeDirection(name: string) {
  return ["h", "j", "k", "l"].includes(name);
}

async function registerLocalRoutesToProxy(
  denops: Denops,
  options: { pid: number; port: number },
) {
  const routes = [
    { proxyPath: "/env", reversePath: "/env" },
    { proxyPath: "/notify", reversePath: "/notify" },
    { proxyPath: "/setreg", reversePath: "/setreg" },
    { proxyPath: "/getreg", reversePath: "/getreg" },
    { proxyPath: "/open", reversePath: "/open" },
    { proxyPath: "/scratch", reversePath: "/scratch" },
    { proxyPath: "/focus-edge", reversePath: "/focus-edge" },
  ];
  for (let attempt = 0; attempt < REGISTER_RETRY_LIMIT; attempt += 1) {
    const results = await Promise.all(
      routes.map((route) =>
        registerLocalRouteOnce(denops, {
          ...options,
          ...route,
        })
      ),
    );
    const ok = results.every((result) => result);
    if (ok) {
      return;
    }
    if (attempt < REGISTER_RETRY_LIMIT - 1) {
      await delay(REGISTER_BACKOFF_BASE_MS * 2 ** attempt);
    }
  }
  console.error("Failed to register local server to nvim-proxy.");
}

async function registerLocalRouteOnce(
  denops: Denops,
  options: {
    pid: number;
    port: number;
    proxyPath: string;
    reversePath: string;
  },
) {
  const proxyUrl = await vars.e.get(denops, "NVIM_PROXY_URL", "");
  if (!proxyUrl) {
    return false;
  }
  const registerUrl = `${proxyUrl.replace(/\/+$/, "")}/register`;
  const payload = {
    pid: options.pid,
    proxy_path: options.proxyPath,
    reverse_path: options.reversePath,
    reverse_port: options.port,
  };
  try {
    const res = await fetch(registerUrl, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(payload),
    });
    return res.ok;
  } catch {
    return false;
  }
}

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

async function ensureProxyServer(denops: Denops) {
  if (await isProxyRunning()) {
    return;
  }
  const started = await startService();
  if (started && await isProxyRunning()) {
    return;
  }
  await notifyInstallNeeded(denops);
}

async function isProxyRunning() {
  try {
    const res = await fetch(`${DEFAULT_PROXY_URL}/health`);
    return res.ok;
  } catch {
    return false;
  }
}

async function startService() {
  switch (Deno.build.os) {
    case "linux":
      return await runCommand([
        "systemctl",
        "--user",
        "start",
        SYSTEMD_SERVICE_NAME,
      ]);
    case "darwin":
      return await startLaunchdService();
    default:
      return false;
  }
}

async function restartService() {
  switch (Deno.build.os) {
    case "linux":
      return await runCommand([
        "systemctl",
        "--user",
        "restart",
        SYSTEMD_SERVICE_NAME,
      ]);
    case "darwin":
      return await startLaunchdService();
    default:
      return false;
  }
}

async function installService(denops: Denops) {
  switch (Deno.build.os) {
    case "linux":
      await installSystemdService(denops);
      break;
    case "darwin":
      await installLaunchdService(denops);
      break;
    default:
      console.error("nvim-proxy: unsupported OS for service install.");
  }
}

async function installSystemdService(denops: Denops) {
  const home = Deno.env.get("HOME");
  if (!home) {
    console.error("nvim-proxy: HOME is not set.");
    return;
  }
  const servicePath = `${home}/.config/systemd/user/${SYSTEMD_SERVICE_NAME}`;
  const proxyPath = resolveProxyPath();
  const denoCommand = await vars.g.get(denops, "nvim_proxy_deno_command", [
    Deno.execPath(),
  ]);
  const content = [
    "[Unit]",
    "Description=Neovim proxy",
    "",
    "[Service]",
    `ExecStart=${denoCommand.join(" ")} run -A --no-lock ${proxyPath}`,
    "Restart=on-failure",
    "",
    "[Install]",
    "WantedBy=default.target",
    "",
  ].join("\n");
  await Deno.mkdir(`${home}/.config/systemd/user`, { recursive: true });
  await Deno.writeTextFile(servicePath, content);
  await runCommand(["systemctl", "--user", "daemon-reload"]);
  await runCommand([
    "systemctl",
    "--user",
    "enable",
    "--now",
    SYSTEMD_SERVICE_NAME,
  ]);
}

async function installLaunchdService(denops: Denops) {
  const home = Deno.env.get("HOME");
  const uid = await resolveUid();
  if (!home || uid === undefined) {
    console.error("nvim-proxy: HOME/UID is not available.");
    return;
  }
  const plistPath = `${home}/Library/LaunchAgents/${LAUNCHD_LABEL}.plist`;
  const proxyPath = resolveProxyPath();
  const denoCommand = await vars.g.get(denops, "nvim_proxy_deno_command", [
    Deno.execPath(),
  ]);
  const stdoutPath = `${home}/Library/Logs/nvim-proxy.log`;
  const stderrPath = `${home}/Library/Logs/nvim-proxy.err.log`;
  const plist = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
    '<plist version="1.0">',
    "<dict>",
    "  <key>Label</key>",
    `  <string>${LAUNCHD_LABEL}</string>`,
    "  <key>ProgramArguments</key>",
    "  <array>",
    ...(denoCommand.map((s) => `    <string>${s}</string>`)),
    "    <string>run</string>",
    "    <string>-A</string>",
    "    <string>--no-lock</string>",
    `    <string>${proxyPath}</string>`,
    "  </array>",
    "  <key>RunAtLoad</key>",
    "  <true/>",
    "  <key>KeepAlive</key>",
    "  <true/>",
    "  <key>StandardOutPath</key>",
    `  <string>${stdoutPath}</string>`,
    "  <key>StandardErrorPath</key>",
    `  <string>${stderrPath}</string>`,
    "</dict>",
    "</plist>",
    "",
  ].join("\n");
  await Deno.mkdir(`${home}/Library/LaunchAgents`, { recursive: true });
  await Deno.writeTextFile(plistPath, plist);
  await runCommand(["launchctl", "bootstrap", `gui/${uid}`, plistPath]);
  await runCommand(["launchctl", "enable", `gui/${uid}/${LAUNCHD_LABEL}`]);
  await runCommand([
    "launchctl",
    "kickstart",
    "-k",
    `gui/${uid}/${LAUNCHD_LABEL}`,
  ]);
}

async function startLaunchdService() {
  const uid = await resolveUid();
  if (uid === undefined) {
    return false;
  }
  return await runCommand([
    "launchctl",
    "kickstart",
    "-k",
    `gui/${uid}/${LAUNCHD_LABEL}`,
  ]);
}

function resolveProxyPath() {
  return fromFileUrl(new URL("./proxy.ts", import.meta.url));
}

async function resolveUid() {
  if (typeof Deno.uid === "function") {
    return Deno.uid();
  }
  const fromEnv = Number(Deno.env.get("UID") ?? "");
  if (Number.isFinite(fromEnv)) {
    return fromEnv;
  }
  const res = await runCommandOutput(["id", "-u"]);
  if (!res) {
    return undefined;
  }
  const parsed = Number(res.trim());
  return Number.isFinite(parsed) ? parsed : undefined;
}

async function runCommand(args: string[]) {
  try {
    const command = new Deno.Command(args[0], {
      args: args.slice(1),
      stdout: "null",
      stderr: "null",
    });
    const { success } = await command.output();
    return success;
  } catch {
    return false;
  }
}

async function runCommandOutput(args: string[]) {
  try {
    const command = new Deno.Command(args[0], {
      args: args.slice(1),
      stdout: "piped",
      stderr: "null",
    });
    const { success, stdout } = await command.output();
    if (!success) {
      return undefined;
    }
    return new TextDecoder().decode(stdout);
  } catch {
    return undefined;
  }
}

async function runCommandOutputAllowFailure(args: string[]) {
  try {
    const command = new Deno.Command(args[0], {
      args: args.slice(1),
      stdout: "piped",
      stderr: "piped",
    });
    const { stdout, stderr } = await command.output();
    const decoder = new TextDecoder();
    const output = [decoder.decode(stdout), decoder.decode(stderr)]
      .map((part) => part.trim())
      .filter((part) => part.length > 0)
      .join("\n");
    return output;
  } catch {
    return undefined;
  }
}

function formatCommand(args: string[]) {
  return args.join(" ");
}

async function notifyInstallNeeded(denops: Denops) {
  const hasNvim = await fn.has(denops, "nvim");
  const message =
    "nvim-proxy service is not running. Run :NvimProxyInstall to set it up.";
  if (hasNvim) {
    try {
      await denops.call("nvim_notify", message, 3, { title: "nvim-proxy" });
      return;
    } catch {
      // Fall through to message output.
    }
  }
  await denops.call("echohl", "WarningMsg");
  await denops.call("echomsg", message);
  await denops.call("echohl", "None");
}

async function collectStatus() {
  const service = await readServiceStatus();
  const proxy = await readProxyStatus();
  const routes = await fetchRoutes();
  return {
    service,
    proxy,
    routes: routes ?? [],
    routes_error: routes ? undefined : "unavailable",
  };
}

async function collectLog() {
  switch (Deno.build.os) {
    case "linux":
      return await readSystemdLog(100);
    case "darwin":
      return await readLaunchdLog(100);
    default:
      return {
        ok: false,
        message: "service manager unavailable",
      };
  }
}

async function readServiceStatus() {
  switch (Deno.build.os) {
    case "linux":
      return await readSystemdStatus();
    case "darwin":
      return await readLaunchdStatus();
    default:
      return { ok: false, message: "service manager unavailable" };
  }
}

async function readSystemdStatus() {
  const commandArgs = [
    "systemctl",
    "--user",
    "status",
    SYSTEMD_SERVICE_NAME,
    "--no-pager",
  ];
  const detail = await runCommandOutputAllowFailure(commandArgs);
  const output = await runCommandOutput([
    "systemctl",
    "--user",
    "show",
    SYSTEMD_SERVICE_NAME,
    "--property=ActiveState,SubState",
    "--no-page",
  ]);
  if (!output) {
    return {
      ok: false,
      message: "systemd: unavailable",
      detail: {
        command: formatCommand(commandArgs),
        output: detail ?? "",
      },
    };
  }
  const active = pickSystemdValue(output, "ActiveState");
  const sub = pickSystemdValue(output, "SubState");
  if (!active) {
    return {
      ok: false,
      message: "systemd: inactive",
      detail: {
        command: formatCommand(commandArgs),
        output: detail ?? "",
      },
    };
  }
  return {
    ok: true,
    message: sub ? `systemd: ${active}/${sub}` : `systemd: ${active}`,
    detail: {
      command: formatCommand(commandArgs),
      output: detail ?? "",
    },
  };
}

async function readSystemdLog(lines: number) {
  const commandArgs = [
    "journalctl",
    "--user",
    "-u",
    SYSTEMD_SERVICE_NAME,
    "-n",
    String(lines),
    "--no-pager",
  ];
  const detail = await runCommandOutputAllowFailure(commandArgs);
  if (detail === undefined) {
    return {
      ok: false,
      message: "systemd: log unavailable",
      detail: {
        command: formatCommand(commandArgs),
        output: "",
      },
    };
  }
  return {
    ok: true,
    message: "systemd: log",
    detail: {
      command: formatCommand(commandArgs),
      output: detail,
    },
  };
}

function pickSystemdValue(output: string, key: string) {
  const line = output.split("\n").find((row) => row.startsWith(`${key}=`));
  if (!line) {
    return undefined;
  }
  return line.slice(key.length + 1).trim() || undefined;
}

async function readLaunchdStatus() {
  const uid = await resolveUid();
  if (uid === undefined) {
    return { ok: false, message: "launchd: unavailable" };
  }
  const commandArgs = ["launchctl", "print", `gui/${uid}/${LAUNCHD_LABEL}`];
  const detail = await runCommandOutputAllowFailure(commandArgs);
  const output = await runCommandOutput([
    "launchctl",
    "print",
    `gui/${uid}/${LAUNCHD_LABEL}`,
  ]);
  if (!output) {
    return {
      ok: false,
      message: "launchd: not loaded",
      detail: {
        command: formatCommand(commandArgs),
        output: detail ?? "",
      },
    };
  }
  const pid = pickLaunchdPid(output);
  return pid
    ? {
      ok: true,
      message: `launchd: running (pid ${pid})`,
      detail: {
        command: formatCommand(commandArgs),
        output: detail ?? "",
      },
    }
    : {
      ok: true,
      message: "launchd: loaded",
      detail: {
        command: formatCommand(commandArgs),
        output: detail ?? "",
      },
    };
}

async function readLaunchdLog(lines: number) {
  const home = Deno.env.get("HOME");
  if (!home) {
    return { ok: false, message: "launchd: log unavailable" };
  }
  const stdoutPath = `${home}/Library/Logs/nvim-proxy.log`;
  const stderrPath = `${home}/Library/Logs/nvim-proxy.err.log`;
  const commandArgs = [
    "sh",
    "-c",
    `tail -n ${lines} ${stderrPath} ${stdoutPath}`,
  ];
  const detail = await runCommandOutputAllowFailure(commandArgs);
  if (detail === undefined) {
    return {
      ok: false,
      message: "launchd: log unavailable",
      detail: {
        command: formatCommand(commandArgs),
        output: "",
      },
    };
  }
  return {
    ok: true,
    message: "launchd: log",
    detail: {
      command: formatCommand(commandArgs),
      output: detail,
    },
  };
}
function pickLaunchdPid(output: string) {
  const line = output.split("\n").find((row) => row.trim().startsWith("pid ="));
  if (!line) {
    return undefined;
  }
  const value = line.split("=").pop()?.trim().replace(/;$/, "");
  return value && value !== "0" ? value : undefined;
}

async function fetchRoutes() {
  try {
    const res = await fetch(`${DEFAULT_PROXY_URL}/routes`);
    if (!res.ok) {
      return undefined;
    }
    const data = await res.json();
    return Array.isArray(data) ? data : undefined;
  } catch {
    return undefined;
  }
}

async function readProxyStatus() {
  try {
    const res = await fetch(`${DEFAULT_PROXY_URL}/health`);
    if (!res.ok) {
      return { ok: false, message: `proxy: HTTP ${res.status}` };
    }
    const data = await res.json().catch(() => ({}));
    if (data && typeof data === "object" && data.status === "ok") {
      return { ok: true, message: `proxy ok (${DEFAULT_PROXY_URL})` };
    }
    return { ok: false, message: "proxy: invalid response" };
  } catch (error) {
    return {
      ok: false,
      message: `proxy: ${
        error instanceof Error ? error.message : String(error)
      }`,
    };
  }
}
