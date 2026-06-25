import { assertEquals } from "@std/assert";
import { pathShorten } from "./path_shorten.ts";

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
