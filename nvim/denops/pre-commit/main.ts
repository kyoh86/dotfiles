import * as vars from "jsr:@denops/std@~8.0.0/variable";
import * as fn from "jsr:@denops/std@~8.0.0/function";
import type { Denops } from "jsr:@denops/std@~8.0.0";

// The global variable name to store the pre-commit server address.
// It maybe used in git hook script.
//
// See: git/hooks/pre-commit
const PRECOMMIT_ADDRESS = "PRECOMMIT_ADDRESS";

// Start a HTTP server to handle pre-commit hook requests.
// The server listens on a random free port and sets the address
// to the global variable `PRECOMMIT_ADDRESS`.
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
    onListen: async ({ hostname, port }) => {
      await vars.e.set(
        denops,
        PRECOMMIT_ADDRESS,
        `${hostname}:${port}`,
      );
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

// Parse the request body as JSON.
async function parseRequestBody(body: ReadableStream<Uint8Array>) {
  const lines = [];
  for await (const line of body.pipeThrough(new TextDecoderStream()).values()) {
    lines.push(line);
  }
  const params = JSON.parse(lines.join("\n"));
  return params;
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
