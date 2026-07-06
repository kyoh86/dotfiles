import { assertEquals } from "@std/assert";
import { parseGinBufferSource } from "./main.ts";

Deno.test("parseGinBufferSource labels index ginedit buffer", () => {
  assertEquals(
    parseGinBufferSource("ginedit:///repo#README.md"),
    {
      scheme: "ginedit",
      worktree: "/repo",
      params: {},
      fragment: "README.md",
      source: "index",
      sourceLabel: "INDEX",
    },
  );
});

Deno.test("parseGinBufferSource labels HEAD ginedit buffer", () => {
  assertEquals(
    parseGinBufferSource("ginedit:///repo;commitish=HEAD#README.md"),
    {
      scheme: "ginedit",
      worktree: "/repo",
      params: { commitish: "HEAD" },
      fragment: "README.md",
      source: "head",
      sourceLabel: "HEAD",
    },
  );
});

Deno.test("parseGinBufferSource labels conflict stages", () => {
  assertEquals(
    parseGinBufferSource("ginedit:///repo;commitish=:2#x")?.sourceLabel,
    "OURS",
  );
  assertEquals(
    parseGinBufferSource("ginedit:///repo;commitish=:3#x")?.sourceLabel,
    "THEIRS",
  );
});

Deno.test("parseGinBufferSource keeps other commitish as revision label", () => {
  assertEquals(
    parseGinBufferSource("ginedit:///repo;commitish=HEAD~1#x")?.sourceLabel,
    "HEAD~1",
  );
});
