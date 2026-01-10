import * as fn from "@denops/std/function";
import * as vars from "@denops/std/variable";
import type { Denops } from "@denops/std";
import { as, ensure, is } from "@core/unknownutil";

const REGISTER_RETRY_LIMIT = 5;
const REGISTER_BACKOFF_BASE_MS = 200;

// Start a HTTP server to handle dirty buffer check requests.
// The server listens on a random free port and sets the address
// The server checks for dirty buffers in the specified directory
// and prompts the user to save or ignore them before committing.
export async function main(denops: Denops): Promise<void> {
  const { finished } = Deno.serve({
    hostname: "127.0.0.1",
    port: 0, // Automatically select free port
    handler: async (req, _info) => {
      if (req.body === null) {
        return new Response("No body", { status: 400 });
      }
      const params = await parseRequestBody(req.body);
      const bufs = await findDirtyBuffers(denops, params.dir);
      if (params.mode === "status") {
        const body = JSON.stringify(
          createStatusResponse(params.dir, bufs, params.limit),
        );
        return new Response(body, {
          headers: { "content-type": "application/json; charset=utf-8" },
        });
      }
      if (bufs.length === 0) {
        return new Response("ok");
      }
      const msg = createConfirmMessage(bufs);
      switch (
        await fn.confirm(denops, msg, "&Yes\n&No")
      ) {
        case 1: // Yes (Ignore them)
          return new Response("ok");
        case 2: // No (Suspend)
          return new Response("skip");
      }
      return new Response("unsupported status", { status: 500 });
    },
    onListen: async ({ port }) => {
      const precommitAddress = `127.0.0.1:${port}`;
      await registerToProxy(denops, { precommitAddress });
    },
  });
  await finished;
}

// Create a confirmation message listing dirty buffers.
function createConfirmMessage(
  bufs: { name: string; bufnr: number; buftype: unknown }[],
) {
  const files = bufs.map((buf) => buf.name);
  const msg = [
    bufs.length > 1 ? "There're dirty buffers." : "There's a dirty buffer.",
    "If you need, you should save them before commit:\n",
    "",
    ...files,
    "",
    "Ignore them and continue?",
  ].join("\n");
  return msg;
}

// Create a status response for shell integration.
function createStatusResponse(
  dir: string,
  bufs: { name: string; bufnr: number; buftype: unknown }[],
  limit?: number,
) {
  const prefix = dir.endsWith("/") ? dir : `${dir}/`;
  const files = bufs.map((buf) => {
    if (buf.name.startsWith(prefix)) {
      return buf.name.slice(prefix.length);
    }
    return buf.name;
  });
  const sliced = typeof limit === "number" ? files.slice(0, limit) : files;
  return {
    total: files.length,
    files: sliced,
    truncated: sliced.length < files.length,
  };
}

// Parse the request body as JSON.
async function parseRequestBody(body: ReadableStream<Uint8Array>) {
  const lines = [];
  for await (const line of body.pipeThrough(new TextDecoderStream()).values()) {
    lines.push(line);
  }
  const parsed = JSON.parse(lines.join("\n"));
  const record = ensure(
    parsed,
    is.ObjectOf({
      dir: is.String,
      mode: as.Optional(is.UnionOf([is.String, is.Undefined])),
      limit: as.Optional(is.UnionOf([is.Number, is.Undefined])),
    }),
  );
  return record;
}

// Find dirty buffers in the specified directory.
async function findDirtyBuffers(denops: Denops, dir: string) {
  const bufinfos = await fn.getbufinfo(denops, { bufmodified: true });
  const bufs = (await Promise.all(bufinfos.map(async (bufinfo) => {
    const buftype = await fn.getbufvar(denops, bufinfo.bufnr, "&buftype");
    return {
      name: bufinfo.name,
      bufnr: bufinfo.bufnr,
      buftype,
    };
  })))
    .filter((buf) =>
      buf.buftype === "" && buf.name !== "" &&
      buf.name.startsWith(dir)
    );
  return bufs;
}

async function registerToProxy(
  denops: Denops,
  options: { precommitAddress: string },
) {
  const pid = await fn.getpid(denops);
  for (let attempt = 0; attempt < REGISTER_RETRY_LIMIT; attempt += 1) {
    const ok = await registerOnce(denops, {
      pid,
      precommitAddress: options.precommitAddress,
    });
    if (ok) {
      return;
    }
    if (attempt < REGISTER_RETRY_LIMIT - 1) {
      await delay(REGISTER_BACKOFF_BASE_MS * 2 ** attempt);
    }
  }
  console.error("Failed to register dirty-bufs server to nvim-proxy.");
}

async function registerOnce(
  denops: Denops,
  options: {
    pid: number;
    precommitAddress: string;
  },
) {
  const proxyUrl = await vars.e.get(denops, "NVIM_PROXY_URL", "");
  if (!proxyUrl) {
    return false;
  }
  const registerUrl = `${proxyUrl.replace(/\/+$/, "")}/register`;
  const payload = {
    pid: options.pid,
    path: "/dirty-bufs",
    target_url: options.precommitAddress,
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
