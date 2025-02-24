import type { Entrypoint } from "jsr:@denops/std@~7.5.0";
import { Router } from "jsr:@kyoh86/denops-router@0.4.2";

import { login } from "./handler/login.ts";
import {
  issueViewBrowse,
  issueViewBrowseCursor,
  issueViewEditBody,
  issueViewEditCursor,
  issueViewNavi,
  issueViewNewComment,
  loadIssueViewer,
} from "./handler/issue-viewer.ts";
import { loadIssueEditor, saveIssueEditor } from "./handler/issue-editor.ts";
import { loadIssueComment, saveIssueComment } from "./handler/issue-comment.ts";
import {
  loadIssueNewComment,
  saveIssueNewComment,
} from "./handler/issue-new-comment.ts";

const ClientID = "Iv23liIclzYxPQJBSI7d";

export const main: Entrypoint = async (denops) => {
  const dispatcher = {
    login: async () => {
      return await login(denops, ClientID);
    },
  };

  const router = new Router("github");
  router.addHandler("issue/view", {
    load: async (ctx, buf) => {
      await loadIssueViewer(denops, ctx, buf);
    },
    actions: {
      prev: async (buf) => {
        await issueViewNavi(denops, router, buf, -1);
      },
      next: async (buf) => {
        await issueViewNavi(denops, router, buf, 1);
      },
      ["edit-body"]: async (buf) => {
        await issueViewEditBody(denops, router, buf);
      },
      ["edit-cursor"]: async (buf) => {
        await issueViewEditCursor(denops, router, buf);
      },
      ["new-comment"]: async (buf) => {
        await issueViewNewComment(denops, router, buf);
      },
      //TODO: Implement delete-comment
      //TODO: Implement minimize-comment https://docs.github.com/ja/graphql/reference/mutations#minimizecomment
      browse: async (buf) => {
        await issueViewBrowse(denops, buf);
      },
      ["browse-cursor"]: async (buf) => {
        await issueViewBrowseCursor(denops, buf);
      },
    },
  });

  router.addHandler("issue/edit", {
    load: async (ctx, buf) => {
      await loadIssueEditor(denops, ctx, buf);
    },
    save: async (_ctx, buf) => {
      await saveIssueEditor(denops, buf);
    },
  });

  router.addHandler("issue/new-comment", {
    load: async (ctx, buf) => {
      await loadIssueNewComment(denops, ctx, buf);
    },
    save: async (_ctx, buf) => {
      await saveIssueNewComment(denops, router, buf);
    },
  });

  router.addHandler("issue/comment", {
    load: async (ctx, buf) => {
      await loadIssueComment(denops, ctx, buf);
    },
    save: async (_ctx, buf) => {
      await saveIssueComment(denops, buf);
    },
  });

  denops.dispatcher = await router.dispatch(denops, dispatcher);
};
