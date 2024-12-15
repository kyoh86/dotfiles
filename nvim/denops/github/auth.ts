import xdg from "https://deno.land/x/xdg@v10.6.0/src/mod.deno.ts";
import { join } from "jsr:@std/path@~1.0.2";
import { ensureDir } from "jsr:@std/fs@~1.0.0";
import type {
  GitHubAppAuthentication,
} from "npm:@octokit/auth-oauth-device@~7.1.1";
import { is, type Predicate } from "jsr:@core/unknownutil@~4.3.0";

async function ensureSessionFilePath() {
  const dir = join(xdg.state(), "ddu-source-github");
  await ensureDir(dir);
  return join(dir, "github-session.json");
}

async function loadSafely() {
  const path = await ensureSessionFilePath();
  try {
    const stored = JSON.parse(await Deno.readTextFile(path));
    if (typeof stored !== "object") {
      return {} as GitHubAppAuthentication;
    }
    return stored as GitHubAppAuthentication;
  } catch {
    return {} as GitHubAppAuthentication;
  }
}

export async function restoreAuthentication() {
  return await loadSafely();
}

export async function storeAuthentication(
  authentication: GitHubAppAuthentication,
) {
  await Deno.writeTextFile(
    await ensureSessionFilePath(),
    JSON.stringify(authentication),
  );
}

const isGitHubAppAuthentication = is.ObjectOf({
  clientType: is.LiteralOf("github-app"),
  clientId: is.String,
  type: is.LiteralOf("token"),
  tokenType: is.LiteralOf("oauth"),
  token: is.String,
}) satisfies Predicate<
  GitHubAppAuthentication
>;

export { isGitHubAppAuthentication };
