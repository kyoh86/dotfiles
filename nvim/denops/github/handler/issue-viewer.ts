import type { Denops } from "jsr:@denops/std@~7.4.0";
import type { Buffer, Router } from "jsr:@kyoh86/denops-router@0.3.0-alpha.6";
import * as buffer from "jsr:@denops/std@~7.4.0/buffer";
import * as option from "jsr:@denops/std@~7.4.0/option";
import * as autocmd from "jsr:@denops/std@~7.4.0/autocmd";
import {
  format as formatDateTime,
  parse as parseDateTime,
} from "jsr:@std/datetime@^0.225.2";

import { getClient } from "../client.ts";
import { getIssueIdentifier } from "./issue-buf.ts";
import { mapDispatch } from "./util.ts";
import { getbufvar, setbufvar } from "jsr:@denops/std@~7.4.0/function";
import { ensure, is } from "jsr:@core/unknownutil@4";
import { systemopen } from "jsr:@lambdalisue/systemopen@~1.0.0";

// Issueを取得してフォーマットする関数
async function fetchAndFormatIssue(
  owner: string,
  repo: string,
  issue_number: number,
): Promise<{ url: string; body: string[] }> {
  const client = await getClient();

  // Issue情報の取得
  const { data: issue } = await client.rest.issues.get({
    owner,
    repo,
    issue_number,
  });
  // コメント一覧の取得
  const { data: comments } = await client.rest.issues.listComments({
    owner,
    repo,
    issue_number,
    per_page: 100,
  });

  // Issueの基本情報整形
  const stateText = issue.state === "open" ? "[open]" : "[closed]";
  const titleSection = [
    `TITLE:>=======================================================================`,
    `#${issue.number} ${stateText} ${issue.title}`,
  ];

  function localTimeString(t: string): string {
    return formatDateTime(
      parseDateTime(t, "yyyy-MM-ddTHH:mm:ssZ"),
      "yyyy-MM-dd HH:mm",
      {},
    );
  }
  // META情報整形
  // ラベル、アサイン、マイルストーン、URLなど
  const labels = issue.labels.map((l) => typeof l === "string" ? l : l.name)
    .join(", ");
  const assignees = issue.assignees?.map((a) => `@${a.login}`).join(", ") || "";
  const milestone = issue.milestone?.title ?? "";
  const repoFullName =
    `${issue.repository?.owner.login}/${issue.repository?.name}`;
  const openedBy = `@${issue.user?.login ?? "unknown"} on ${
    localTimeString(issue.created_at)
  }`;
  const metaSection = [
    `META:>=========================================================================`,
    `[Repository]   : ${repoFullName}`,
    `[Opened by]    : ${openedBy}`,
    ...(labels.length > 0 ? [`[Labels]       : ${labels}`] : []),
    ...(assignees.length > 0 ? [`[Assignees]    : ${assignees}`] : []),
    ...(milestone != "" ? [`[Milestone]    : ${milestone}`] : []),
    `[URL]          : ${issue.html_url}`,
    ``,
  ];

  // BODY部分
  // Issue本文（issue.body）をMarkdownと想定
  // 空行を適宜挟む
  const body = issue.body?.split("\n") ?? [];
  const bodySection = [
    `BODY:>=========================================================================`,
    ...body.map((line) => `  ${line.trimEnd()}`.trimEnd()),
    ``,
  ];

  // COMMENTS部分
  const commentsSectionHeader = comments.length > 0
    ? [
      `COMMENTS (${comments.length}):>=================================================================`,
      "",
    ]
    : [];

  const commentLines: string[] = [];
  if (comments.length > 0) {
    for (let i = 0; i < comments.length; i++) {
      const c = comments[i];
      // コメントヘッダ行の例:
      // `-- #1 @charlie 2024-12-12 09:15 [Author, Owner] ------------------------------`
      const numberLine = `-- #${i + 1} @${c.user?.login ?? "unknown"} ${
        localTimeString(c.created_at)
      }`;
      // Edited/Author/Ownerフラグの抽出 (ここでは例として簡易的に)
      const metaFlags: string[] = [];
      if (c.author_association === "OWNER") metaFlags.push("Owner");
      if (c.author_association === "COLLABORATOR") metaFlags.push("Author"); // 例: collaboratorをAuthor相当とする
      if (
        localTimeString(c.updated_at) &&
        localTimeString(c.updated_at) !== localTimeString(c.created_at)
      ) {
        metaFlags.push("Edited");
      }

      const metaStr = metaFlags.length > 0 ? ` [${metaFlags.join(", ")}]` : "";
      const sep = "--------------------------------";
      commentLines.push(`${numberLine}${metaStr} ${sep}`);
      commentLines.push("");
      // コメント本文
      const cBody = c.body?.split("\n") ?? [];
      for (const cl of cBody) {
        commentLines.push(`  ${cl}`);
      }
      commentLines.push(``);
    }
  }

  return {
    url: issue.html_url,
    body: [
      ...titleSection,
      ``,
      ...metaSection,
      ...bodySection,
      ...commentsSectionHeader,
      ...commentLines,
    ],
  };
}

async function setKeymap(denops: Denops, buf: Buffer) {
  await buffer.ensure(denops, buf.bufnr, async () => {
    const opt = { denops, buffer: true, method: "router:action" };
    await mapDispatch({
      ...opt,
      lhs: "<Plug>(github-issue-viewer-next)",
      args: [buf.bufnr, "next", {}],
    });
    await mapDispatch({
      ...opt,
      lhs: "<Plug>(github-issue-viewer-prev)",
      args: [buf.bufnr, "prev", {}],
    });
    await mapDispatch({
      ...opt,
      lhs: "<Plug>(github-issue-viewer-edit)",
      args: [buf.bufnr, "edit", {}],
    });
    await mapDispatch({
      ...opt,
      lhs: "<Plug>(github-issue-viewer-comment)",
      args: [buf.bufnr, "comment", {}],
    });
    await mapDispatch({
      ...opt,
      lhs: "<Plug>(github-issue-viewer-browse)",
      args: [buf.bufnr, "browse", {}],
    });
  });
}

export async function loadIssueViewer(denops: Denops, buf: Buffer) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  const { url, body: lines } = await fetchAndFormatIssue(owner, repo, num);
  await buffer.replace(denops, buf.bufnr, lines);
  await setKeymap(denops, buf);
  await setbufvar(denops, buf.bufnr, "denops_github_issue_url", url);

  // Issueにコメントを追記したら自動で再読み込みする
  await autocmd.group(
    denops,
    `denops-github:issue:buffer:${buf.bufnr}`,
    (helper) => {
      helper.define(
        "User",
        `denops-github:issue:comment-new;owner=${owner}&repo=${repo}&num=${num}`,
        `execute bufwinnr(${buf.bufnr}) .. "windo e"`,
        { nested: true },
      );
    },
  );
  await option.filetype.setBuffer(denops, buf.bufnr, "github-issue-view");
  // filetypeに応じたsyntax設定は別ファイルで行う
  // ref: ../../../syntax/github-issue-view.vim
}

export async function issueViewNavi(
  denops: Denops,
  router: Router,
  buf: Buffer,
  d: number,
) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  await router.open(denops, "issue/view", { owner, repo, num: `${num + d}` });
}

export async function issueViewEdit(
  denops: Denops,
  router: Router,
  buf: Buffer,
) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  await router.open(denops, "issue/edit", { owner, repo, num: `${num}` }, "", {
    split: "split-above",
  });
}

export async function issueViewComment(
  denops: Denops,
  router: Router,
  buf: Buffer,
) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  await router.open(
    denops,
    "issue/comment",
    { owner, repo, num: `${num}` },
    "",
    {
      split: "split-below",
    },
  );
}

export async function issueViewBrowse(
  denops: Denops,
  buf: Buffer,
) {
  await systemopen(
    ensure(
      await getbufvar(denops, buf.bufnr, "denops_github_issue_url"),
      is.String,
    ),
  );
}
