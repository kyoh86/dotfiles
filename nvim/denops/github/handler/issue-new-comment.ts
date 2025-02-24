import type { Denops } from "jsr:@denops/std@~7.5.0";
import type {
  Buffer,
  LoadContext,
  Router,
} from "jsr:@kyoh86/denops-router@0.4.2";
import * as option from "jsr:@denops/std@~7.5.0/option";
import * as buffer from "jsr:@denops/std@~7.5.0/buffer";
import * as autocmd from "jsr:@denops/std@~7.5.0/autocmd";
import { getbufline } from "jsr:@denops/std@~7.5.0/function";

import { getClient } from "../client.ts";
import { getIssueIdentifier } from "./issue-buf.ts";

export async function loadIssueNewComment(
  denops: Denops,
  _ctx: LoadContext,
  buf: Buffer,
) {
  await option.endofline.setBuffer(denops, buf.bufnr, false);
  await option.fixendofline.setBuffer(denops, buf.bufnr, false);
  await option.filetype.setBuffer(denops, buf.bufnr, "markdown");
  await option.bufhidden.setBuffer(denops, buf.bufnr, "wipe");
}

export async function saveIssueNewComment(
  denops: Denops,
  router: Router,
  buf: Buffer,
) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  const bodyLines = await getbufline(denops, buf.bufnr, 1, "$");
  const client = await getClient();
  const comment = await client.rest.issues.createComment({
    owner,
    repo,
    issue_number: num,
    body: bodyLines.join("\n"),
  });
  await option.modified.setBuffer(denops, buf.bufnr, false);
  await buffer.concrete(denops, buf.bufnr);

  await router.open(denops, "issue/comment", {
    owner,
    repo,
    num: num.toString(),
    commentId: comment.data.id.toString(),
  });
  // await execute(denops, `${buf.bufnr}bdelete!`);
  // It is not necessary to delete the buffer: the buffer will be deleted when the window is closed. ('bufhidden' is "wipe")

  // Issueにコメントを追記したらIssueビューを自動で再読み込みする
  await autocmd.emit(
    denops,
    "User",
    `denops-github:issue:new-comment;owner=${owner}&repo=${repo}&num=${num}`,
  );
}
