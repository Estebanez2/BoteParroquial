import {
  createRemoteJWKSet,
  jwtVerify,
  type JWTVerifyGetKey,
} from "npm:jose@6.1.0";

export const firebaseProject = "boteparroquial";
const googleKeys = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
  { timeoutDuration: 5000 },
);

export async function verifyFirebaseToken(
  token: string,
  keys: JWTVerifyGetKey = googleKeys,
): Promise<string> {
  const { payload } = await jwtVerify(token, keys, {
    algorithms: ["RS256"],
    issuer: `https://securetoken.google.com/${firebaseProject}`,
    audience: firebaseProject,
    requiredClaims: ["exp", "iat", "auth_time", "sub"],
  });
  const now = Math.floor(Date.now() / 1000);
  if (
    typeof payload.sub !== "string" || payload.sub.length === 0 ||
    payload.sub.length > 128 || typeof payload.iat !== "number" ||
    payload.iat > now || typeof payload.auth_time !== "number" ||
    payload.auth_time > now || payload.auth_time < 0
  ) {
    throw new Error("Invalid Firebase identity");
  }
  return payload.sub;
}
