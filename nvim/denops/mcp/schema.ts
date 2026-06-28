import * as z from "zod";

const bufferRefSchema = {
  bufnr: z.number().int().optional(),
  name: z.string().optional(),
  match: z.enum(["exact", "suffix", "contains"]).optional(),
};

const bufferResolveOutput = {
  bufnr: z.number().int(),
  name: z.string(),
  reason: z.string().optional(),
  candidates: z.array(z.object({
    bufnr: z.number().int(),
    name: z.string(),
  })).optional(),
};

export const toolDefinitions = [
  {
    name: "nvim_buffers",
    title: "List Neovim buffers",
    description: "Return buffers from the selected Neovim instance.",
    inputSchema: z.object({
      dir: z.string().optional(),
      modifiedOnly: z.boolean().optional(),
      limit: z.number().int().positive().optional(),
    }).strict(),
    outputSchema: z.object({
      total: z.number().int(),
      buffers: z.array(z.object({
        name: z.string(),
        bufnr: z.number().int(),
        modified: z.boolean(),
        buftype: z.string(),
        listed: z.boolean(),
        loaded: z.boolean(),
      })),
    }),
  },
  {
    name: "nvim_reload_buffer",
    title: "Reload buffer from disk",
    description: "Reload a buffer without changing the current window.",
    inputSchema: z.object(bufferRefSchema).strict(),
    outputSchema: z.object({
      ...bufferResolveOutput,
      reloaded: z.boolean(),
    }),
  },
  {
    name: "nvim_get_buffer_content",
    title: "Get buffer content",
    description: "Return buffer lines without changing the current window.",
    inputSchema: z.object({
      ...bufferRefSchema,
      start: z.number().int().positive().optional(),
      end: z.number().int().positive().optional(),
      limit: z.number().int().positive().optional(),
    }).strict(),
    outputSchema: z.object({
      ...bufferResolveOutput,
      start: z.number().int(),
      end: z.number().int(),
      total: z.number().int(),
      truncated: z.boolean(),
      lines: z.array(z.string()),
    }),
  },
  {
    name: "nvim_save_buffer",
    title: "Save buffer",
    description: "Write a buffer to disk without changing the current window.",
    inputSchema: z.object(bufferRefSchema).strict(),
    outputSchema: z.object({
      ...bufferResolveOutput,
      saved: z.boolean(),
    }),
  },
  {
    name: "nvim_open_file",
    title: "Open file",
    description: "Open a file in the selected Neovim instance.",
    inputSchema: z.object({
      path: z.string(),
      focus: z.boolean().optional(),
    }).strict(),
    outputSchema: z.object({
      bufnr: z.number().int(),
      name: z.string(),
      opened: z.boolean(),
      focused: z.boolean(),
      reason: z.string().optional(),
    }),
  },
  {
    name: "nvim_current_buffer",
    title: "Get current buffer",
    description: "Return the current buffer and cursor position.",
    inputSchema: z.object({}).strict(),
    outputSchema: z.object({
      name: z.string(),
      bufnr: z.number().int(),
      modified: z.boolean(),
      cursor: z.object({
        line: z.number().int(),
        col: z.number().int(),
      }),
      cwd: z.string(),
    }),
  },
  {
    name: "nvim_cwd",
    title: "Get Neovim working directory",
    description: "Return the current working directory in Neovim.",
    inputSchema: z.object({}).strict(),
    outputSchema: z.object({
      cwd: z.string(),
    }),
  },
  {
    name: "nvim_current_selection",
    title: "Get current selection",
    description: "Return the current visual selection, if any.",
    inputSchema: z.object({}).strict(),
    outputSchema: z.object({
      hasSelection: z.boolean(),
      mode: z.string(),
      start: z.object({
        line: z.number().int(),
        col: z.number().int(),
      }).optional(),
      end: z.object({
        line: z.number().int(),
        col: z.number().int(),
      }).optional(),
      lines: z.array(z.string()),
      text: z.string(),
    }),
  },
  {
    name: "nvim_list_items",
    title: "Get quickfix or loclist items",
    description: "Return quickfix or location list items.",
    inputSchema: z.object({
      list: z.enum(["quickfix", "loclist"]).optional(),
      winid: z.number().int().positive().optional(),
      limit: z.number().int().positive().optional(),
    }).strict(),
    outputSchema: z.object({
      list: z.string(),
      title: z.string().optional(),
      total: z.number().int(),
      items: z.array(z.object({
        bufnr: z.number().int(),
        filename: z.string(),
        lnum: z.number().int(),
        col: z.number().int(),
        end_lnum: z.number().int().optional(),
        end_col: z.number().int().optional(),
        text: z.string(),
        type: z.string().optional(),
        valid: z.boolean(),
      })),
    }),
  },
  {
    name: "nvim_diagnostics",
    title: "Get LSP diagnostics",
    description: "Return diagnostics from Neovim's built-in diagnostic API.",
    inputSchema: z.object({
      ...bufferRefSchema,
      severity: z.enum(["error", "warn", "info", "hint"]).optional(),
    }).strict(),
    outputSchema: z.object({
      total: z.number().int(),
      diagnostics: z.array(z.object({
        bufnr: z.number().int(),
        lnum: z.number().int(),
        col: z.number().int(),
        end_lnum: z.number().int().optional(),
        end_col: z.number().int().optional(),
        severity: z.number().int(),
        severity_name: z.string(),
        message: z.string(),
        source: z.string().optional(),
        code: z.union([z.string(), z.number()]).optional(),
      })),
      reason: z.string().optional(),
      candidates: z.array(z.object({
        bufnr: z.number().int(),
        name: z.string(),
      })).optional(),
    }),
  },
  {
    name: "help_query",
    title: "Query Neovim help tags",
    description:
      "Search Neovim help tags and return context from the matching help file.",
    inputSchema: z.object({
      query: z.string().min(1),
      context: z.number().int().positive().optional(),
      limit: z.number().int().positive().optional(),
    }).strict(),
    outputSchema: z.object({
      query: z.string(),
      total: z.number().int(),
      matches: z.array(z.object({
        tag: z.string(),
        file: z.string(),
        path: z.string(),
        excmd: z.string(),
        tagfile: z.string(),
        matchedBy: z.enum(["exact", "prefix"]),
        found: z.boolean(),
        line: z.number().int(),
        start: z.number().int(),
        end: z.number().int(),
        context: z.array(z.string()),
      })),
    }),
  },
] as const;

export type ToolName = typeof toolDefinitions[number]["name"];

export function findToolDefinition(name: string) {
  return toolDefinitions.find((tool) => tool.name === name);
}
