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
import {
  bufnr,
  getbufvar,
  getcurpos,
  setbufvar,
} from "jsr:@denops/std@~7.4.0/function";
import { ensure, is } from "jsr:@core/unknownutil@4";
import { systemopen } from "jsr:@lambdalisue/systemopen@~1.0.0";

import { getClient } from "../client.ts";
import { getIssueIdentifier } from "./issue-buf.ts";
import { mapDispatch } from "./util.ts";
import { query as queryIssue } from "../query/issue.ts";
import { AttributedLines } from "../anchored_lines.ts";

// Issueを取得してフォーマットする関数
async function fetchAndFormatIssue(
  owner: string,
  repo: string,
  issue_number: number,
): Promise<{ url: string; lines: AttributedLines }> {
  const client = await getClient();
  const lines = new AttributedLines();

  // Issue情報の取得
  const { url, ...issue } = await queryIssue(client, owner, repo, issue_number);

  // Issueの基本情報整形
  const stateText = issue.state === "open" ? "[open]" : "[closed]";

  // Title部分
  lines.expand([
    `TITLE:>`.padEnd(80, "="),
    `#${issue.number} ${stateText} ${issue.title}`,
  ], "title");

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
  lines.expand([
    `META:>`.padEnd(80, "="),
    `[Repository]   : ${repoFullName}`,
    `[Opened by]    : ${openedBy}`,
  ]);
  if (labels.length > 0) {
    lines.push(`[Labels]       : ${labels}`, "label");
  }
  if (assignees.length > 0) {
    lines.push(`[Assignees]    : ${assignees}`, "assignee");
  }
  if (milestone != "") {
    lines.push(`[Milestone]    : ${milestone}`, "milestone");
  }
  lines.push(`[URL]          : ${url}`, "url");

  // BODY部分
  // Issue本文（issue.body）をMarkdownと想定
  // 空行を適宜挟む
  lines.push(`BODY:>`.padEnd(80, "="), "body");
  const bodyLines = issue.body?.split(/\r?\n/)?.map((l) => indentLine(l));
  if (bodyLines) {
    lines.expand(bodyLines, "body");
  }
  if (issue.comments.length == 0) {
    return { url, lines };
  }

  // COMMENTS部分
  lines.push(`COMMENTS (${issue.comments.length}):>`.padEnd(80, "="));

  if (issue.comments.length > 0) {
    for (let i = 0; i < issue.comments.length; i++) {
      lines.push(`:`);
      const c = issue.comments[i];
      // コメントヘッダ行の例:
      // `-- C-#1 @charlie 2024-12-12 09:15 [Author, Owner] ------------------------------`
      // `-- M-#1 @charlie 2024-12-12 09:15 [Author, Owner, OUTDATED] --------------------
      const numberLine = `-- ${c.isMinimized ? "M" : "C"}-#${i + 1} @${
        c.author.login ?? "unknown"
      } ${localTimeString(c.createdAt)}`;
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
      if (c.isMinimized) metaFlags.push(c.minimizedReason ?? "Minimized");

      const metaStr = metaFlags.length > 0 ? ` [${metaFlags.join(", ")}]` : "";
      lines.push(
        `${numberLine}${metaStr} `.padEnd(80, "-"),
        `comment:${c.databaseId}`,
      );
      lines.push("", `comment:${c.databaseId}`);
      // コメント本文
      const cBody = c.body?.split(/\r?\n/) ?? [];
      for (const cl of cBody) {
        lines.push(indentLine(cl), `comment:${c.databaseId}`);
      }
    }
  }

  return { url, lines };
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
      lhs: "<Plug>(github-issue-viewer-edit-cursor)",
      args: [buf.bufnr, "edit-cursor", {}],
    });
    await mapDispatch({
      ...opt,
      lhs: "<Plug>(github-issue-viewer-edit-body)",
      args: [buf.bufnr, "edit-body", {}],
    });
    await mapDispatch({
      ...opt,
      lhs: "<Plug>(github-issue-viewer-new-comment)",
      args: [buf.bufnr, "new-comment", {}],
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

  const { url, lines } = await fetchAndFormatIssue(owner, repo, num);
  await buffer.replace(denops, buf.bufnr, lines.lines);
  await option.filetype.setBuffer(denops, buf.bufnr, "github-issue-view");
  await option.syntax.setBuffer(denops, buf.bufnr, "github-issue-view");
  if (!ctx.firstTime) {
    return;
  }
  await setKeymap(denops, buf);
  await setbufvar(denops, buf.bufnr, "denops_github_issue_url", url);
  await setbufvar(
    denops,
    buf.bufnr,
    "denops_github_issue_line_attrs",
    lines.attrs,
  );

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

export async function issueViewEditBody(
  denops: Denops,
  router: Router,
  buf: Buffer,
) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  await router.open(denops, "issue/edit", { owner, repo, num: `${num}` }, "", {
    split: "split-above",
  });
}

export async function issueViewEditCursor(
  denops: Denops,
  router: Router,
  buf: Buffer,
) {
  const { owner, repo, num } = getIssueIdentifier(buf);
  const [bufnum, lnum] = await getcurpos(denops);
  const curbuf = (bufnum === 0) ? await bufnr(denops, "%") : bufnum;

  if (curbuf !== buf.bufnr) {
    throw new Error(
      `cursor is in buffer ${curbuf}, is not in target buffer ${buf.bufnr}`,
    );
  }
  const attrs = ensure(
    await getbufvar(denops, buf.bufnr, "denops_github_issue_line_attrs"),
    is.ArrayOf(is.UnionOf([is.String, is.Null])),
  );
  const attr = attrs[lnum - 1];
  if (attr === null) {
    return;
  }
  if (attr === "body") {
    await router.open(
      denops,
      "issue/edit",
      { owner, repo, num: `${num}` },
      "",
      {
        split: "split-above",
      },
    );
    return;
  }
  if (attr.startsWith("comment:")) {
    const commentId = attr.slice("comment:".length);
    await router.open(
      denops,
      "issue/comment",
      { owner, repo, num: `${num}`, commentId },
      "",
      {
        split: "split-above",
      },
    );
    return;
  }
}

export async function issueViewNewComment(
  denops: Denops,
  router: Router,
  buf: Buffer,
) {
  const { owner, repo, num } = getIssueIdentifier(buf);

  await router.open(
    denops,
    "issue/new-comment",
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
