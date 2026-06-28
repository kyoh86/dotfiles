import type { Denops } from "@denops/std";
import { findToolDefinition, type ToolName } from "../schema.ts";
import { listBuffers, openFile } from "./buffers.ts";
import { getBufferContent, reloadBuffer, saveBuffer } from "./buffers.ts";
import { getDiagnostics } from "./diagnostics.ts";
import { queryHelp } from "./help.ts";
import { getListItems } from "./list_items.ts";
import { getCurrentBuffer, getCurrentSelection, getCwd } from "./state.ts";

export async function callTool(
  denops: Denops,
  name: string,
  args: unknown,
): Promise<unknown> {
  const definition = findToolDefinition(name);
  if (!definition) {
    throw new RpcError(404, `Unknown tool: ${name}`);
  }
  const parsed = definition.inputSchema.safeParse(args ?? {});
  if (!parsed.success) {
    throw new RpcError(400, parsed.error.message);
  }
  return await dispatchTool(denops, name as ToolName, parsed.data);
}

async function dispatchTool(
  denops: Denops,
  name: ToolName,
  args: Record<string, unknown>,
) {
  switch (name) {
    case "nvim_buffers":
      return await (async () => {
        const buffers = await listBuffers(denops, args);
        return { total: buffers.length, buffers };
      })();
    case "nvim_reload_buffer":
      return await reloadBuffer(denops, args);
    case "nvim_get_buffer_content":
      return await getBufferContent(denops, args);
    case "nvim_save_buffer":
      return await saveBuffer(denops, args);
    case "nvim_open_file":
      return await openFile(denops, args as { path: string; focus?: boolean });
    case "nvim_current_buffer":
      return await getCurrentBuffer(denops);
    case "nvim_cwd":
      return await getCwd(denops);
    case "nvim_current_selection":
      return await getCurrentSelection(denops);
    case "nvim_list_items":
      return await getListItems(denops, {
        list: (args.list as "quickfix" | "loclist" | undefined) ?? "quickfix",
        winid: args.winid as number | undefined,
        limit: args.limit as number | undefined,
      });
    case "nvim_diagnostics":
      return await getDiagnostics(denops, args);
    case "help_query":
      return await queryHelp(denops, {
        query: args.query as string,
        context: (args.context as number | undefined) ?? 4,
        limit: (args.limit as number | undefined) ?? 3,
      });
  }
}

export class RpcError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = "RpcError";
  }
}
