import { ensure, is } from "jsr:@core/unknownutil@^4.3.0";
import type { Buffer } from "jsr:@kyoh86/denops-router@0.3.6";

export function getIssueIdentifier(buf: Buffer) {
  const owner = ensure(buf.bufname.params?.owner, is.String, {
    message: "a 'owner' parmeter must be a string",
  });
  const repo = ensure(buf.bufname.params?.repo, is.String, {
    message: "a 'repo' parmeter must be a string",
  });
  const numStr = ensure(buf.bufname.params?.num, is.String, {
    message: "a 'num' parmeter must be a string",
  });
  return { owner, repo, num: parseInt(numStr, 10) };
}
