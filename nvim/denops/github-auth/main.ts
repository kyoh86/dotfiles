import type { Entrypoint } from "jsr:@denops/std@~7.4.0";
import { batch } from "jsr:@denops/std@~7.4.0/batch";
import { echo } from "jsr:@denops/std@~7.4.0/helper";
import { systemopen } from "jsr:@lambdalisue/systemopen@~1.0.0";

import {
  createOAuthDeviceAuth,
} from "https://esm.sh/@octokit/auth-oauth-device@7.1.1";
import type { OnVerificationCallback } from "https://esm.sh/v135/@octokit/auth-oauth-device@7.1.1/dist-types/types.d.ts";

const ClientID = "Iv23liIclzYxPQJBSI7d";

export const main: Entrypoint = (denops) => {
  denops.dispatcher = {
    login: async () => {
      const options: {
        onVerification: OnVerificationCallback;
      } = {
        onVerification: (v) => {
          batch(denops, async (denops) => {
            await echo(
              denops,
              [
                `Open ${v.verification_uri}`,
                `and put your one-time code : ${v.user_code}`,
              ].join("\n "),
            );
          });
          systemopen(v.verification_uri);
          // TODO: If it does not inistalled, kyoh86-dotfiles should be installed.
          // https://github.com/settings/apps/kyoh86-dotfiles/installations
        },
      };

      const auth = createOAuthDeviceAuth({
        clientType: "github-app",
        clientId: ClientID,
        ...options,
      });
      return await auth({ type: "oauth" });
    },
  };
};
