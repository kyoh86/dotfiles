const DEFAULT_HOST = "127.0.0.1";
const DEFAULT_PORT = 37125;

type InstanceInfo = {
  pid: number;
  cwd: string;
  mcpUrl: string;
  precommitUrl: string;
  servername?: string;
  updatedAt: number;
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
    if (pathname === "/register" && req.method === "POST") {
      return await handleRegister(req);
    }

    if (pathname === "/mcp") {
      return await handleMcp(req);
    }
    if (pathname === "/pre-commit" && req.method === "POST") {
      return await handlePreCommit(req);
    }

    return new Response("Not found", { status: 404 });
  };

  return Deno.serve({ hostname: host, port, handler });
}

async function handleMcp(req: Request) {
  const pid = parsePid(req.headers.get("x-nvim-pid"));
  if (!pid) {
    return json({ error: "NVIM_PID is required" }, 400);
  }
  const instance = instances.get(pid);
  if (!instance) {
    return json({ error: `Unknown Neovim PID: ${pid}` }, 404);
  }
  const target = ensureHttpUrl(instance.mcpUrl);
  const forwardReq = new Request(target, {
    method: req.method,
    headers: forwardHeaders(req.headers),
    body: req.method === "GET" || req.method === "HEAD" ? null : req.body,
  });
  return await fetch(forwardReq);
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
  const existing = instances.get(pid);
  const cwd = typeof record.cwd === "string" && record.cwd !== ""
    ? record.cwd
    : existing?.cwd;
  const mcpUrl = typeof record.mcp_url === "string" && record.mcp_url !== ""
    ? record.mcp_url
    : existing?.mcpUrl;
  const precommitUrl =
    typeof record.precommit_url === "string" && record.precommit_url !== ""
      ? record.precommit_url
      : existing?.precommitUrl;
  if (!cwd) {
    return json({ error: "Missing cwd" }, 400);
  }
  if (!mcpUrl && !precommitUrl) {
    return json({ error: "Missing endpoints" }, 400);
  }
  instances.set(pid, {
    pid,
    cwd,
    mcpUrl: mcpUrl ?? "",
    precommitUrl: precommitUrl ?? "",
    servername: typeof record.servername === "string"
      ? record.servername
      : existing?.servername,
    updatedAt: Date.now(),
  });
  return json({ ok: true });
}

async function handlePreCommit(req: Request) {
  const pid = parsePid(req.headers.get("x-nvim-pid"));
  if (!pid) {
    return new Response("NVIM_PID is required", { status: 400 });
  }
  const instance = instances.get(pid);
  if (!instance || !instance.precommitUrl) {
    return new Response("ok");
  }
  const url = ensureHttpUrl(instance.precommitUrl);
  try {
    const res = await fetch(url, {
      method: req.method,
      headers: forwardHeaders(req.headers),
      body: req.method === "GET" || req.method === "HEAD" ? null : req.body,
    });
    const text = await res.text();
    return new Response(text);
  } catch (error) {
    return new Response(
      `error: ${error instanceof Error ? error.message : String(error)}`,
      { status: 500 },
    );
  }
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
