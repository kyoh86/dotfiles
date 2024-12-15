import { restoreAuthentication, storeAuthentication } from "./auth.ts";
import { Octokit as OctokitCore } from "npm:@octokit/core@6.1.2";
import { restEndpointMethods } from "npm:@octokit/plugin-rest-endpoint-methods@13.2.6";
import { paginateRest } from "npm:@octokit/plugin-paginate-rest@11.3.6";

export const Octokit = OctokitCore.plugin(restEndpointMethods).plugin(
  paginateRest,
);
import { createOAuthDeviceAuth } from "npm:@octokit/auth-oauth-device@7.1.1";
import { systemopen } from "jsr:@lambdalisue/systemopen@~1.0.0";
type Verification = {
  device_code: string;
  user_code: string;
  verification_uri: string;
  expires_in: number;
  interval: number;
};

export async function authenticate(
  force?: boolean,
) {
  const options: {
    onVerification: (verification: Verification) => void;
  } = {
    onVerification: (verification) => {
      console.info("Open", verification.verification_uri);
      console.info("Enter code:", verification.user_code);
      systemopen(verification.verification_uri);
      // TODO: If it does not inistalled, ddu-source-github should be installed.
      // https://github.com/settings/apps/ddu-source-github/installations
    },
  };

  const stored = await restoreAuthentication();
  if (!force && stored) {
    return {
      ...stored, // Set stored clientType and clientId
      ...options,
      authentication: stored,
    };
  }

  const auth = createOAuthDeviceAuth({
    clientType: "github-app",
    clientId: ClientID,
    ...options,
  });
  const newone = await auth({ type: "oauth" });

  storeAuthentication(newone);
  return {
    ...newone, // Set got clientType and clientId
    ...options,
    authentication: newone,
  };
}

const ClientID = "Iv1.784dcbad252102e3";

export async function getClient() {
  return new Octokit({
    authStrategy: createOAuthDeviceAuth,
    auth: await authenticate(),
  });
}
