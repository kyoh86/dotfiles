const DEFAULT_HOST = "127.0.0.1";
const DEFAULT_PORT = 37125;

type InstanceInfo = {
  pid: number;
  routes: Map<string, string>;
};

const instances = new Map<number, InstanceInfo>();

export type ProxyServerOptions = {
  host?: string;
  port?: number;
};

export function startProxyServer(options: ProxyServerOptions = {}) {
  const host = options.host ?? DEFAULT_HOST;
  const port = options.port ?? DEFAULT_PORT;

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

  return Deno.serve({ hostname: host, port, handler });
}

function listRoutes() {
  return Array.from(instances.values()).map((instance) => ({
    pid: instance.pid,
    routes: Object.fromEntries(instance.routes.entries()),
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
  const routes = existing?.routes ?? new Map<string, string>();
  routes.set(path, ensureHttpUrl(targetUrl));
  instances.set(pid, { pid, routes });
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

function ensureHttpUrl(url: string) {
  if (url.startsWith("http://") || url.startsWith("https://")) {
    return url;
  }
  return `http://${url}`;
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
