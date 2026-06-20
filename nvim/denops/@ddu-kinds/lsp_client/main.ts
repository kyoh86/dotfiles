import { BaseKind } from "@shougo/ddu-vim/kind";
import { ActionFlags, type Actions } from "@shougo/ddu-vim/types";
import { as, is, Predicate } from "@core/unknownutil";

export type ActionData = {
  attached_buffers: Record<string, string>; // Each buffer's last used `languageId`.
  exit_timeout: number | boolean; // See |vim.lsp.ClientConfig|.
  id: number; // The id allocated to the client.
  initialized?: true;
  name: string; // See |vim.lsp.ClientConfig|.
  offset_encoding: "utf-8" | "utf-16" | "utf-32"; // See |vim.lsp.ClientConfig|.
  root_dir?: string; // See |vim.lsp.ClientConfig|.
};

export const isActionData = is.ObjectOf({
  attached_buffers: is.RecordOf(is.String, is.String),
  exit_timeout: is.UnionOf([is.Number, is.Boolean]),
  id: is.Number,
  initialized: as.Optional(is.LiteralOf(true)),
  name: is.String,
  offset_encoding: is.UnionOf([
    is.LiteralOf("utf-8"),
    is.LiteralOf("utf-16"),
    is.LiteralOf("utf-32"),
  ]),
  root_dir: as.Optional(is.String),
}) satisfies Predicate<ActionData>;

type Params = {
  force?: boolean;
};

export class Kind extends BaseKind<Params> {
  override actions: Actions<Params> = {
    stop: async ({ items, denops, actionParams }) => {
      for await (const item of items) {
        await denops.call(
          "luaeval",
          `vim.lsp.get_client_by_id(_A.id):stop(_A.force)`,
          {
            id: (item.action as ActionData).id,
            force: !!actionParams.force,
          },
        );
      }
      return ActionFlags.None;
    },
    restart: async ({ items, denops }) => {
      for await (const item of items) {
        await denops.cmd(
          `lsp restart  ${(item.action as ActionData).name}`,
          {},
        );
      }
      return ActionFlags.None;
    },
  };

  params(): Params {
    return {};
  }
}
