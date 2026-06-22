import { resolve } from "@std/path/posix";

export type PathShortenOptions = {
  cwd?: string;
  homeDir?: string | null;
};

export function pathShorten(
  path = ".",
  options: PathShortenOptions = {},
): string {
  let absPath = resolve(options.cwd ?? Deno.cwd(), path);
  const homeDir = options.homeDir === undefined
    ? Deno.env.get("HOME")
    : options.homeDir;

  if (homeDir && absPath.startsWith(homeDir)) {
    absPath = `~${absPath.slice(homeDir.length)}`;
  }

  return shortenPath(absPath);
}

function shortenPath(path: string): string {
  if (path === "" || path === ".") {
    return ".";
  }

  const segments = path.split("/");
  const isAbsolute = segments[0] === "";
  let filtered = segments.filter((segment) => segment !== "");

  let worktreeBranch = "";
  for (const [index, segment] of filtered.entries()) {
    if (segment !== ".worktree" || index + 1 >= filtered.length) {
      continue;
    }
    if (index + 2 === filtered.length) {
      worktreeBranch = filtered[index + 1];
      filtered = [
        ...filtered.slice(0, index),
        ...filtered.slice(index + 2),
      ];
    }
    break;
  }

  if (filtered.length <= 3) {
    let result = path;
    if (worktreeBranch !== "") {
      result = result.replace(`/.worktree/${worktreeBranch}`, "");
      result = result.replace(`\\.worktree\\${worktreeBranch}`, "");
      result = `${result}@${worktreeBranch}`;
    }
    return result;
  }

  const result = filtered.slice(0, -1).map((segment) => {
    if (segment.length > 1 && segment[0] === ".") {
      return segment.slice(0, 2);
    }
    return segment[0];
  });
  result.push(filtered[filtered.length - 1]);

  let output = result.join("/");
  if (isAbsolute) {
    output = `/${output}`;
  }
  if (worktreeBranch !== "") {
    output = `${output}@${worktreeBranch}`;
  }
  return output;
}
