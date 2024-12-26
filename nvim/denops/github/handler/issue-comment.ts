import type { Denops } from "jsr:@denops/std@~7.4.0";
import type { Buffer } from "jsr:@kyoh86/denops-router@0.3.5";
import { getClient } from "../client.ts";
import * as option from "jsr:@denops/std@~7.4.0/option";
import * as buffer from "jsr:@denops/std@~7.4.0/buffer";
import * as autocmd from "jsr:@denops/std@~7.4.0/autocmd";
import { getbufline, setbufvar } from "jsr:@denops/std@~7.4.0/function";
import { getIssueIdentifier } from "./issue-buf.ts";

export async function loadIssueComment(denops: Denops, buf: Buffer) {
  await option.filetype.setBuffer(denops, buf.bufnr, "markdown");
  await option.bufhidden.setBuffer(denops, buf.bufnr, "wipe");
}

export async function saveIssueComment(denops: Denops, buf: Buffer) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  const bodyLines = await getbufline(denops, buf.bufnr, 1, "$");
  const client = await getClient();
  await client.rest.issues.createComment({
    owner,
    repo,
    issue_number: num,
    body: bodyLines.join("\n"),
  });
  await setbufvar(denops, buf.bufnr, "&modified", 0);
  await buffer.concrete(denops, buf.bufnr);

  // Issueにコメントを追記したらIssueビューを自動で再読み込みする
  await autocmd.emit(
    denops,
    "User",
    `denops-github:issue:comment-new;owner=${owner}&repo=${repo}&num=${num}`,
  );
}
