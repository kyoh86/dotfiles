import * as vars from "https://deno.land/x/denops_std@v6.4.0/variable/mod.ts";
import * as fn from "https://deno.land/x/denops_std@v6.4.0/function/mod.ts";
import type { Denops } from "https://deno.land/x/denops_std@v6.4.0/mod.ts";

const PRECOMMIT_ADDRESS = "PRECOMMIT_ADDRESS";

export async function main(denops: Denops): Promise<void> {
  const { finished } = Deno.serve({
    hostname: "127.0.0.1",
    port: 0, // Automatically select free port
    handler: async (req, _info) => {
      if (req.body === null) {
        return new Response("No body", { status: 400 });
      }
      const lines = [];
      for await (
        const line of req.body.pipeThrough(new TextDecoderStream()).values()
      ) {
        lines.push(line);
      }
      const params = JSON.parse(lines.join("\n"));
      const bufinfos = await fn.getbufinfo(denops, { bufmodified: true });
      const bufs = await Promise.all(bufinfos.map(async (bufinfo) => {
        const buftype = await fn.getbufvar(denops, bufinfo.bufnr, "&buftype");
        return {
          name: bufinfo.name,
          bufnr: bufinfo.bufnr,
          buftype,
        };
      }));
      return new Response(
        bufs
          .filter((buf) =>
            buf.buftype === "" && buf.name !== "" &&
            buf.name.startsWith(params.dir)
          )
          .map((buf) => buf.name + "\n")
          .join(),
      );
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
