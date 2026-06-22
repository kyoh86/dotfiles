import { assertEquals } from "@std/assert";
import { pathShorten, shortenPath } from "./path_shorten.ts";

Deno.test("shortenPath", async (t) => {
  const tests = [
    ["", "."],
    [".", "."],
    ["single", "single"],

    ["~", "~"],
    ["~/single", "~/single"],
    ["~/a/b", "~/a/b"],
    ["~/a/b/c", "~/a/b/c"],

    ["~/Long/name", "~/Long/name"],
    ["~/Long/name/path", "~/L/n/path"],
    ["~/Long/.name/path", "~/L/.n/path"],

    ["/", "/"],
    ["/single", "/single"],
    ["/a/b", "/a/b"],
    ["/a/b/c", "/a/b/c"],
    ["/a/b/c/d", "/a/b/c/d"],

    ["/Long/name/to", "/Long/name/to"],
    ["/Long/name/to/path", "/L/n/t/path"],
    ["/Long/.name/to/path", "/L/.n/t/path"],

    ["~/Long/name/to/path/.worktree/main", "~/L/n/t/path@main"],
    [
      "~/Long/name/to/path/.worktree/other/structure",
      "~/L/n/t/p/.w/o/structure",
    ],
  ] as const;

  for (const [input, want] of tests) {
    await t.step(input, () => {
      assertEquals(shortenPath(input), want);
    });
  }
});

Deno.test("pathShorten resolves relative path and home prefix", () => {
  assertEquals(
    pathShorten("repo/.worktree/main", {
      cwd: "/home/user/Projects/github.com/kyoh86",
      homeDir: "/home/user",
    }),
    "~/P/g/k/repo@main",
  );
});

Deno.test("pathShorten resolves parent segments", () => {
  assertEquals(
    pathShorten("../dotfiles/./nvim", {
      cwd: "/home/user/Projects/github.com/kyoh86/dotfiles",
      homeDir: "/home/user",
    }),
    "~/P/g/k/d/nvim",
  );
});
