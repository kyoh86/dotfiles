import type { Denops } from "jsr:@denops/std@~7.4.0";
import type {
  Buffer,
  LoadContext,
  Router,
} from "jsr:@kyoh86/denops-router@0.4.2";
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
import { query as queryIssue } from "../query/issue.ts";

// Issueを取得してフォーマットする関数
async function fetchAndFormatIssue(
  owner: string,
  repo: string,
  issue_number: number,
): Promise<{ url: string; body: string[] }> {
  const client = await getClient();

  // Issue情報の取得
  const issue = await queryIssue(client, owner, repo, issue_number);

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
  const assignees = issue.assignees.map((a) => `@${a.login}`).join(", ") || "";
  const milestone = issue.milestone?.title ?? "";
  const repoFullName = `${owner}/${repo}`;
  const openedBy = `@${issue.author.login ?? "unknown"} on ${
    localTimeString(issue.createdAt)
  }`;
  const metaSection = [
    `META:>=========================================================================`,
    `[Repository]   : ${repoFullName}`,
    `[Opened by]    : ${openedBy}`,
    ...(labels.length > 0 ? [`[Labels]       : ${labels}`] : []),
    ...(assignees.length > 0 ? [`[Assignees]    : ${assignees}`] : []),
    ...(milestone != "" ? [`[Milestone]    : ${milestone}`] : []),
    `[URL]          : ${issue.url}`,
    ``,
  ];

  // BODY部分
  // Issue本文（issue.body）をMarkdownと想定
  // 空行を適宜挟む
  const bodySection = [
    `BODY:>=========================================================================`,
    ...issue.body?.split(/\r?\n/)?.map((l) => indentLine(l)) ?? [],
    ``,
  ];

  // COMMENTS部分
  const commentsSectionHeader = issue.comments.length > 0
    ? [
      `COMMENTS (${issue.comments.length}):>=================================================================`,
    ]
    : [];

  const commentLines: string[] = [];
  if (issue.comments.length > 0) {
    for (let i = 0; i < issue.comments.length; i++) {
      commentLines.push(`:`);
      const c = issue.comments[i];
      // コメントヘッダ行の例:
      // `-- C-#1 @charlie 2024-12-12 09:15 [Author, Owner] ------------------------------`
      const numberLine = `-- C-#${i + 1} @${c.author.login ?? "unknown"} ${
        localTimeString(c.createdAt)
      }`;
      // Edited/Author/Ownerフラグの抽出 (ここでは例として簡易的に)
      const metaFlags: string[] = [];
      if (c.authorAssociation === "OWNER") metaFlags.push("Owner");
      if (c.authorAssociation === "COLLABORATOR") metaFlags.push("Author"); // 例: collaboratorをAuthor相当とする
      if (
        localTimeString(c.updatedAt) &&
        localTimeString(c.updatedAt) !== localTimeString(c.createdAt)
      ) {
        metaFlags.push("Edited");
      }

      const metaStr = metaFlags.length > 0 ? ` [${metaFlags.join(", ")}]` : "";
      const sep = "--------------------------------";
      commentLines.push(`${numberLine}${metaStr} ${sep}`);
      commentLines.push("");
      // コメント本文
      const cBody = c.body?.split(/\r?\n/) ?? [];
      for (const cl of cBody) {
        commentLines.push(indentLine(cl));
      }
    }
  }

  return {
    url: issue.url,
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

function indentLine(line: string, level: number = 1): string {
  return line.trim() === "" ? line : `${"  ".repeat(level)}${line}`;
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

export async function loadIssueViewer(
  denops: Denops,
  ctx: LoadContext,
  buf: Buffer,
) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  const { url, body: lines } = await fetchAndFormatIssue(owner, repo, num);
  await buffer.replace(denops, buf.bufnr, lines);
  await option.filetype.setBuffer(denops, buf.bufnr, "github-issue-view");
  await option.syntax.setBuffer(denops, buf.bufnr, "github-issue-view");
  if (!ctx.firstTime) {
    return;
  }
  await setKeymap(denops, buf);
  await setbufvar(denops, buf.bufnr, "denops_github_issue_url", url);

  // Issueにコメントを追記したら自動で再読み込みする
  await autocmd.group(
    denops,
    `denops-github:issue:buffer:${buf.bufnr}`,
    (helper) => {
      helper.remove("*");
      helper.define(
        "User",
        `denops-github:issue:*;owner=${owner}&repo=${repo}&num=${num}`,
        `execute bufwinnr(${buf.bufnr}) .. "windo e"`,
        { nested: true },
      );
    },
  );
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
