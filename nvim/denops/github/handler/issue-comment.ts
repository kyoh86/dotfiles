import type { Denops } from "jsr:@denops/std@~7.5.0";
import type { Buffer, LoadContext } from "jsr:@kyoh86/denops-router@0.4.2";
import * as option from "jsr:@denops/std@~7.5.0/option";
import * as buffer from "jsr:@denops/std@~7.5.0/buffer";
import * as autocmd from "jsr:@denops/std@~7.5.0/autocmd";
import { getbufline } from "jsr:@denops/std@~7.5.0/function";

import { getClient } from "../client.ts";
import { getIssueIdentifier } from "./issue-buf.ts";

export async function loadIssueComment(
  denops: Denops,
  _ctx: LoadContext,
  buf: Buffer,
) {
  await option.endofline.setBuffer(denops, buf.bufnr, false);
  await option.fixendofline.setBuffer(denops, buf.bufnr, false);
  await option.filetype.setBuffer(denops, buf.bufnr, "markdown");
  await option.bufhidden.setBuffer(denops, buf.bufnr, "wipe");
  const { owner, repo, num, commentId } = getIssueIdentifier(buf);
  if (!commentId) {
    throw new Error("commentId is required");
  }
  const client = await getClient();
  const comment = await client.rest.issues.getComment({
    owner,
    repo,
    num,
    comment_id: commentId,
  });
  const lines = comment.data.body?.split("\n");
  if (lines) {
    await buffer.replace(denops, buf.bufnr, lines);
  }
}

export async function saveIssueComment(denops: Denops, buf: Buffer) {
  const { owner, repo, num, commentId } = getIssueIdentifier(buf);
  if (!commentId) {
    throw new Error("commentId is required");
  }

  const bodyLines = await getbufline(denops, buf.bufnr, 1, "$");
  const client = await getClient();
  await client.rest.issues.updateComment({
    owner,
    repo,
    issue_number: num,
    comment_id: commentId,
    body: bodyLines.join("\n"),
  });
  await option.modified.setBuffer(denops, buf.bufnr, false);
  await buffer.concrete(denops, buf.bufnr);

  // Issueのコメントを更新したらIssueビューを自動で再読み込みする
  await autocmd.emit(
    denops,
    "User",
    `denops-github:issue:update-comment;owner=${owner}&repo=${repo}&num=${num}`,
  );
}
