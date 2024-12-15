import type { Entrypoint } from "jsr:@denops/std@~7.4.0";
import { Router } from "jsr:@kyoh86/denops-router@0.3.0-alpha.6";
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
      await login(denops, ClientID);
    },
  };

  const router = new Router("github");
  router.handle("issue/view", {
    load: async (buf) => {
      await loadIssueViewer(denops, buf);
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

  router.handle("issue/edit", {
    load: async (buf) => {
      await loadIssueEditor(denops, buf);
    },
    save: async (buf) => {
      await saveIssueEditor(denops, buf);
    },
  });

  router.handle("issue/comment", {
    load: async (buf) => {
      await loadIssueComment(denops, buf);
    },
    save: async (buf) => {
      await saveIssueComment(denops, buf);
    },
  });

  denops.dispatcher = await router.dispatch(denops, dispatcher);
};
