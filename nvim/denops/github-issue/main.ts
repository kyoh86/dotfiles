import type { Entrypoint } from "jsr:@denops/std@~7.4.0";
import { Router } from "jsr:@kyoh86/denops-router@0.3.0-alpha.6";
import * as buffer from "jsr:@denops/std@~7.4.0/buffer";
import * as option from "jsr:@denops/std@~7.4.0/option";
import { ensure, is } from "jsr:@core/unknownutil@^4.3.0";
import { getClient } from "./client.ts";

// Issueを取得してフォーマットする関数
async function fetchAndFormatIssue(
  owner: string,
  repo: string,
  issue_number: number,
): Promise<string[]> {
  const client = await getClient();

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
    `${issue.number} ${stateText} ${issue.title}`,
  ];

  // META情報整形
  // ラベル、アサイン、マイルストーン、URLなど
  const labels = issue.labels.map((l) => typeof l === "string" ? l : l.name)
    .join(", ");
  const assignees = issue.assignees?.map((a) => `@${a.login}`).join(", ") || "";
  const milestone = issue.milestone?.title ?? "";
  const repoFullName = `${owner}/${repo}`;
  const openedBy = `@${issue.user?.login ?? "unknown"} on ${issue.created_at}`;
  const metaSection = [
    `META:>=========================================================================`,
    `[Repository]   : ${repoFullName}`,
    `[Opened by]    : ${openedBy}`,
    `[Labels]       : ${labels}`,
    `[Assignees]    : ${assignees}`,
    `[Milestone]    : ${milestone}`,
    `[URL]          : ${issue.html_url}`,
    ``,
  ];

  // BODY部分
  // Issue本文（issue.body）をMarkdownと想定
  // 空行を適宜挟む
  const body = issue.body?.split("\n") ?? [];
  const bodySection = [
    `BODY:>=========================================================================`,
    ...body.map((line) => `  ${line}`),
    ``,
  ];

  // COMMENTS部分
  const commentsSectionHeader = comments.length > 0
    ? [
      `COMMENTS (${comments.length}):>=================================================================`,
    ]
    : [];

  const commentLines: string[] = [];
  if (comments.length > 0) {
    for (let i = 0; i < comments.length; i++) {
      const c = comments[i];
      // コメントヘッダ行の例:
      // `-- #1 @charlie 2024-12-12 09:15 [Author, Owner] ------------------------------`
      const numberLine = `-- #${i + 1} @${
        c.user?.login ?? "unknown"
      } ${c.created_at}`;
      // Edited/Author/Ownerフラグの抽出 (ここでは例として簡易的に)
      const metaFlags: string[] = [];
      if (c.author_association === "OWNER") metaFlags.push("Owner");
      if (c.author_association === "COLLABORATOR") metaFlags.push("Author"); // 例: collaboratorをAuthor相当とする
      if (c.updated_at && c.updated_at !== c.created_at) {
        metaFlags.push("Edited");
      }

      const metaStr = metaFlags.length > 0 ? ` [${metaFlags.join(", ")}]` : "";
      const sep = "--------------------------------";
      commentLines.push(`${numberLine}${metaStr} ${sep}`);
      // コメント本文
      const cBody = c.body?.split("\n") ?? [];
      for (const cl of cBody) {
        commentLines.push(`  ${cl}`);
      }
      commentLines.push(``);
    }
  }

  return [
    ``,
    `[N] Next Issue    [P] Prev Issue    [E] Edit    [C] Add Comment    [Q] Quit`,
    ``,
    ...titleSection,
    ``,
    ...metaSection,
    ...bodySection,
    ...commentsSectionHeader,
    ...commentLines,
  ];
}

export const main: Entrypoint = async (denops) => {
  const dispatcher = {};

  const router = new Router("github");
  router.handle("issue", {
    load: async (buf) => {
      const owner = ensure(buf.bufname.params?.owner, is.String, {
        message: "a 'owner' parmeter must be a string",
      });
      const repo = ensure(buf.bufname.params?.repo, is.String, {
        message: "a 'repo' parmeter must be a string",
      });
      const num = ensure(buf.bufname.params?.num, is.String, {
        message: "a 'num' parmeter must be a string",
      });
      const issueNumber = parseInt(num, 10);

      const lines = await fetchAndFormatIssue(owner, repo, issueNumber);
      // 新規バッファを開いて表示する
      // 一例として、現在バッファをクリアして表示
      await buffer.replace(denops, buf.bufnr, lines);
      await option.filetype.setBuffer(denops, buf.bufnr, "github-issue");
      // syntaxファイルのfiletype設定などは別途autocmdで行う想定
    },
  });
  denops.dispatcher = await router.dispatch(denops, dispatcher);
};

// 使い方（Neovim側コマンドライン）
// :Denops <plugin-name> showIssue owner repo 1234
