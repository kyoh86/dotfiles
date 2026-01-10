const DEFAULT_HOST = "127.0.0.1";
const DEFAULT_PORT = 37125;
const DEFAULT_HEALTH_INTERVAL_MS = 10 * 60 * 1000;
const DEFAULT_HEALTH_FAILURE_LIMIT = 3;
const DEFAULT_HEALTH_TIMEOUT_MS = 2000;
const STATE_VERSION = 1;

type InstanceInfo = {
  pid: number;
  routes: Map<string, RouteInfo>;
};

const instances = new Map<number, InstanceInfo>();
let healthMonitorStarted = false;

type RouteInfo = {
  targetUrl: string;
  failureCount: number;
};

export type ProxyServerOptions = {
  host?: string;
  port?: number;
};

export function startProxyServer(options: ProxyServerOptions = {}) {
  const host = options.host ?? DEFAULT_HOST;
  const port = options.port ?? DEFAULT_PORT;

  loadState();

  const handler = async (req: Request) => {
    const { pathname } = new URL(req.url);
    if (pathname === "/health") {
      return json({ status: "ok" });
    }
    if (pathname === "/routes") {
      return json(listRoutes());
    }
    if (pathname === "/register" && req.method === "POST") {
      return await handleRegister(req);
    }

    return await handleProxy(req, pathname);
  };

  startHealthMonitor();
  return Deno.serve({ hostname: host, port, handler });
}

function listRoutes() {
  return Array.from(instances.values()).map((instance) => ({
    pid: instance.pid,
    routes: Object.fromEntries(
      Array.from(instance.routes.entries(), ([path, route]) => [
        path,
        route.targetUrl,
      ]),
    ),
  }));
}

async function handleRegister(req: Request) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return json({ error: "Invalid body" }, 400);
  }
  const record = body as Record<string, unknown>;
  const pid = Number(record.pid ?? 0);
  if (!pid) {
    return json({ error: "Missing pid" }, 400);
  }
  const path = typeof record.path === "string" ? record.path : "";
  const targetUrl = typeof record.target_url === "string"
    ? record.target_url
    : "";
  if (!path || !targetUrl) {
    return json({ error: "Missing route" }, 400);
  }
  const existing = instances.get(pid);
  const routes = existing?.routes ?? new Map<string, RouteInfo>();
  routes.set(path, {
    targetUrl: ensureHttpUrl(targetUrl),
    failureCount: 0,
  });
  instances.set(pid, { pid, routes });
  void saveState();
  return json({ ok: true });
}

async function handleProxy(req: Request, pathname: string) {
  const pid = parsePid(req.headers.get("x-nvim-pid"));
  if (!pid) {
    return json({ error: "NVIM_PID is required" }, 400);
  }
  const instance = instances.get(pid);
  const target = instance?.routes.get(pathname);
  if (!target) {
    return json({ error: `Unknown Neovim PID: ${pid}` }, 404);
  }
  const forwardReq = new Request(target, {
    method: req.method,
    headers: forwardHeaders(req.headers),
    body: req.method === "GET" || req.method === "HEAD" ? null : req.body,
  });
  return await fetch(forwardReq);
}

function startHealthMonitor() {
  if (healthMonitorStarted) {
    return;
  }
  healthMonitorStarted = true;
  const interval = DEFAULT_HEALTH_INTERVAL_MS;
  const failureLimit = DEFAULT_HEALTH_FAILURE_LIMIT;
  const timeoutMs = DEFAULT_HEALTH_TIMEOUT_MS;
  const run = async () => {
    await sweepRoutes(interval, failureLimit, timeoutMs);
  };
  void run();
  setInterval(() => {
    void run();
  }, interval);
}

async function sweepRoutes(
  intervalMs: number,
  failureLimit: number,
  timeoutMs: number,
) {
  for (const [pid, instance] of instances.entries()) {
    let changed = false;
    for (const [path, route] of instance.routes.entries()) {
      const ok = await checkHealth(route.targetUrl, timeoutMs);
      if (ok) {
        route.failureCount = 0;
        continue;
      }
      route.failureCount += 1;
      if (route.failureCount >= failureLimit) {
        instance.routes.delete(path);
        changed = true;
      }
    }
    if (instance.routes.size === 0) {
      instances.delete(pid);
      changed = true;
    }
    if (changed) {
      void saveState();
    }
  }
  void intervalMs;
}

async function checkHealth(targetUrl: string, timeoutMs: number) {
  const url = buildHealthUrl(targetUrl);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: controller.signal });
    return res.ok;
  } catch {
    return false;
  } finally {
    clearTimeout(timer);
  }
}

function buildHealthUrl(targetUrl: string) {
  try {
    const url = new URL(targetUrl);
    url.pathname = "/health";
    url.search = "";
    url.hash = "";
    return url.toString();
  } catch {
    return `${targetUrl.replace(/\/+$/, "")}/health`;
  }
}

function ensureHttpUrl(url: string) {
  if (url.startsWith("http://") || url.startsWith("https://")) {
    return url;
  }
  return `http://${url}`;
}

function loadState() {
  const path = resolveStatePath();
  if (!path) {
    return;
  }
  try {
    const raw = Deno.readTextFileSync(path);
    const parsed = JSON.parse(raw) as {
      version?: number;
      instances?: Array<{ pid: number; routes: Record<string, string> }>;
    };
    if (parsed.version !== STATE_VERSION || !Array.isArray(parsed.instances)) {
      return;
    }
    for (const item of parsed.instances) {
      if (!item || typeof item.pid !== "number") {
        continue;
      }
      const routes = new Map<string, RouteInfo>();
      if (item.routes && typeof item.routes === "object") {
        for (const [path, target] of Object.entries(item.routes)) {
          if (typeof target !== "string" || target === "") {
            continue;
          }
          routes.set(path, {
            targetUrl: ensureHttpUrl(target),
            failureCount: 0,
          });
        }
      }
      if (routes.size > 0) {
        instances.set(item.pid, { pid: item.pid, routes });
      }
    }
  } catch (error) {
    console.error("nvim-proxy: failed to load state", error);
  }
}

async function saveState() {
  const path = resolveStatePath();
  if (!path) {
    return;
  }
  const payload = {
    version: STATE_VERSION,
    instances: Array.from(instances.values()).map((instance) => ({
      pid: instance.pid,
      routes: Object.fromEntries(
        Array.from(instance.routes.entries(), ([path, route]) => [
          path,
          route.targetUrl,
        ]),
      ),
    })),
  };
  try {
    await Deno.mkdir(resolveStateDir(), { recursive: true });
    await Deno.writeTextFile(path, JSON.stringify(payload));
  } catch (error) {
    console.error("nvim-proxy: failed to save state", error);
  }
}

function resolveStateDir() {
  const base = Deno.env.get("XDG_STATE_HOME") ??
    (Deno.env.get("HOME") ? `${Deno.env.get("HOME")}/.local/state` : "");
  return base ? `${base}/nvim-proxy` : "";
}

function resolveStatePath() {
  const dir = resolveStateDir();
  if (!dir) {
    return undefined;
  }
  return `${dir}/routes.json`;
}

function parsePid(value: string | null) {
  if (!value) {
    return undefined;
  }
  const parsed = Number(value);
  if (Number.isFinite(parsed) && parsed > 0) {
    return parsed;
  }
  return undefined;
}

function forwardHeaders(headers: Headers) {
  const next = new Headers(headers);
  next.delete("host");
  next.delete("content-length");
  return next;
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

if (import.meta.main) {
  startProxyServer();
}
