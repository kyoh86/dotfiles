import type { Denops } from "jsr:@denops/std@~7.5.0";
import type { Buffer, LoadContext } from "jsr:@kyoh86/denops-router@0.4.2";
import { getClient } from "../client.ts";
import * as autocmd from "jsr:@denops/std@~7.5.0/autocmd";
import * as buffer from "jsr:@denops/std@~7.5.0/buffer";
import * as option from "jsr:@denops/std@~7.5.0/option";
import { getbufline } from "jsr:@denops/std@~7.5.0/function";
import { getIssueIdentifier } from "./issue-buf.ts";

export async function loadIssueEditor(
  denops: Denops,
  _ctx: LoadContext,
  buf: Buffer,
) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  const client = await getClient();

  const { data: { body } } = await client.rest.issues.get({
    owner,
    repo,
    issue_number: num,
  });
  if (body) {
    const lv = await option.undolevels.getBuffer(denops, buf.bufnr);
    await option.undolevels.setBuffer(denops, buf.bufnr, -1);
    await buffer.replace(denops, buf.bufnr, body.split(/\r?\n/));
    await option.undolevels.setBuffer(denops, buf.bufnr, lv);
  }
  await option.endofline.setBuffer(denops, buf.bufnr, false);
  await option.fixendofline.setBuffer(denops, buf.bufnr, false);
  await option.filetype.setBuffer(denops, buf.bufnr, "markdown");
  await option.bufhidden.setBuffer(denops, buf.bufnr, "wipe");
}

export async function saveIssueEditor(denops: Denops, buf: Buffer) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  const bodyLines = await getbufline(denops, buf.bufnr, 1, "$");
  const client = await getClient();
  await client.rest.issues.update({
    owner,
    repo,
    issue_number: num,
    body: bodyLines.join("\n"),
  });
  await option.modified.setBuffer(denops, buf.bufnr, false);

  // Issueを編集したらIssueビューを自動で再読み込みする
  await autocmd.emit(
    denops,
    "User",
    `denops-github:issue:update-body;owner=${owner}&repo=${repo}&num=${num}`,
  );
}
