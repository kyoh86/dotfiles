import * as vars from "@denops/std/variable";
import * as fn from "@denops/std/function";
import type { Denops } from "@denops/std";
import { fromFileUrl } from "@std/path";
const DEFAULT_PROXY_URL = "http://127.0.0.1:37125";
const SYSTEMD_SERVICE_NAME = "nvim-proxy.service";
const LAUNCHD_LABEL = "com.kyoh86.nvim-proxy";

export async function main(denops: Denops): Promise<void> {
  denops.dispatcher = {
    install: async () => {
      await installService();
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
  };

  const autostart = await vars.g.get(denops, "nvim_proxy_autostart", 1);
  if (autostart !== 0) {
    await ensureProxyServer(denops);
  }

  const pid = await fn.getpid(denops);

  await vars.e.set(denops, "NVIM_PROXY_URL", DEFAULT_PROXY_URL);
  await vars.e.set(denops, "NVIM_PID", String(pid));
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

async function installService() {
  switch (Deno.build.os) {
    case "linux":
      await installSystemdService();
      break;
    case "darwin":
      await installLaunchdService();
      break;
    default:
      console.error("nvim-proxy: unsupported OS for service install.");
  }
}

async function installSystemdService() {
  const home = Deno.env.get("HOME");
  if (!home) {
    console.error("nvim-proxy: HOME is not set.");
    return;
  }
  const servicePath = `${home}/.config/systemd/user/${SYSTEMD_SERVICE_NAME}`;
  const proxy_path = resolveProxyPath();
  const denoPath = Deno.execPath();
  const content = [
    "[Unit]",
    "Description=Neovim proxy",
    "",
    "[Service]",
    `ExecStart=${denoPath} run -A --no-lock ${proxy_path}`,
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

async function installLaunchdService() {
  const home = Deno.env.get("HOME");
  const uid = await resolveUid();
  if (!home || uid === undefined) {
    console.error("nvim-proxy: HOME/UID is not available.");
    return;
  }
  const plistPath = `${home}/Library/LaunchAgents/${LAUNCHD_LABEL}.plist`;
  const proxy_path = resolveProxyPath();
  const denoPath = Deno.execPath();
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
    `    <string>${denoPath}</string>`,
    "    <string>run</string>",
    "    <string>-A</string>",
    "    <string>--no-lock</string>",
    `    <string>${proxy_path}</string>`,
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
  const output = await runCommandOutput([
    "systemctl",
    "--user",
    "show",
    SYSTEMD_SERVICE_NAME,
    "--property=ActiveState,SubState",
    "--no-page",
  ]);
  if (!output) {
    return { ok: false, message: "systemd: unavailable" };
  }
  const active = pickSystemdValue(output, "ActiveState");
  const sub = pickSystemdValue(output, "SubState");
  if (!active) {
    return { ok: false, message: "systemd: inactive" };
  }
  return {
    ok: true,
    message: sub ? `systemd: ${active}/${sub}` : `systemd: ${active}`,
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
  const output = await runCommandOutput([
    "launchctl",
    "print",
    `gui/${uid}/${LAUNCHD_LABEL}`,
  ]);
  if (!output) {
    return { ok: false, message: "launchd: not loaded" };
  }
  const pid = pickLaunchdPid(output);
  return pid
    ? { ok: true, message: `launchd: running (pid ${pid})` }
    : { ok: true, message: "launchd: loaded" };
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
