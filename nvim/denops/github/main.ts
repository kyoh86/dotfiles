import type { Entrypoint } from "jsr:@denops/std@~7.4.0";
import { Router } from "jsr:@kyoh86/denops-router@0.4.2";
import { login } from "./handler/login.ts";
import {
  issueViewBrowse,
  issueViewComment,
  issueViewEdit,
  issueViewNavi,
  loadIssueViewer,
} from "./handler/issue-viewer.ts";
import { loadIssueEditor, saveIssueEditor } from "./handler/issue-editor.ts";
import { loadIssueComment, saveIssueComment } from "./handler/issue-comment.ts";

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
      edit: async (buf) => {
        await issueViewEdit(denops, router, buf);
      },
      comment: async (buf) => {
        await issueViewComment(denops, router, buf);
      },
      browse: async (buf) => {
        await issueViewBrowse(denops, buf);
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
