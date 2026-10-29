import { importPKCS8, SignJWT } from "npm:jose@6.1.0";

const project = "boteparroquial";
const tokenEndpoint = "https://oauth2.googleapis.com/token";
const scope = "https://www.googleapis.com/auth/firebase.messaging";

export class FcmError extends Error {
  constructor(readonly code: string, readonly retryable = false) {
    super(code);
  }
}

export interface FcmMessage {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface Credentials {
  project_id: string;
  client_email: string;
  private_key: string;
}

/** Server-only secret. Never load a service account in Flutter or photo-access. */
export function parseFcmCredentials(json: string): Credentials {
  try {
    const value = JSON.parse(json);
    if (
      value.type !== "service_account" || value.project_id !== project ||
      typeof value.client_email !== "string" ||
      !value.client_email.endsWith(`@${project}.iam.gserviceaccount.com`) ||
      typeof value.private_key !== "string" ||
      !value.private_key.startsWith("-----BEGIN PRIVATE KEY-----") ||
      (value.token_uri !== undefined && value.token_uri !== tokenEndpoint)
    ) throw new Error();
    return {
      project_id: project,
      client_email: value.client_email,
      private_key: value.private_key,
    };
  } catch {
    // Do not expose the input, private key or parsing exception in logs.
    throw new FcmError("invalid_server_credentials");
  }
}

/**
 * Transport only: the caller must resolve current membership/preferences and
 * durable delivery deduplication before calling this module. No public handler.
 */
export function createFcmSender(
  credentialsJson: string,
  options: { fetch?: typeof fetch; now?: () => number } = {},
) {
  const credentials = parseFcmCredentials(credentialsJson);
  const request = options.fetch ?? fetch;
  const now = options.now ?? Date.now;
  let cached: { value: string; expiresAt: number } | undefined;
  let refreshing: Promise<string> | undefined;

  async function post(url: string, init: RequestInit): Promise<Response> {
    try {
      return await request(url, {
        ...init,
        signal: AbortSignal.timeout(15000),
        redirect: "error",
      });
    } catch {
      throw new FcmError("transport_unavailable", true);
    }
  }

  async function refresh(): Promise<string> {
    let assertion: string;
    try {
      const key = await importPKCS8(credentials.private_key, "RS256");
      const seconds = Math.floor(now() / 1000);
      assertion = await new SignJWT({ scope })
        .setProtectedHeader({ alg: "RS256", typ: "JWT" })
        .setIssuer(credentials.client_email)
        .setAudience(tokenEndpoint)
        .setIssuedAt(seconds)
        .setExpirationTime(seconds + 3600)
        .sign(key);
    } catch {
      throw new FcmError("invalid_server_credentials");
    }
    const started = now();
    const response = await post(tokenEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    });
    if (!response.ok) {
      throw new FcmError("server_authorization_failed", response.status >= 500);
    }
    const data = await response.json().catch(() => null);
    if (
      typeof data?.access_token !== "string" || !data.access_token ||
      !Number.isInteger(data.expires_in) || data.expires_in <= 60 ||
      data.expires_in > 3600 || data.token_type !== "Bearer"
    ) throw new FcmError("invalid_authorization_response");
    cached = {
      value: data.access_token,
      expiresAt: started + (data.expires_in - 60) * 1000,
    };
    return cached.value;
  }

  async function accessToken(): Promise<string> {
    if (cached && now() < cached.expiresAt) return cached.value;
    if (!refreshing) refreshing = refresh();
    try {
      return await refreshing;
    } finally {
      refreshing = undefined;
    }
  }

  return {
    /** Validation is the default. Sending is an explicit future worker action. */
    async send(
      message: FcmMessage,
      { validateOnly = true }: { validateOnly?: boolean } = {},
    ): Promise<"validated" | "sent" | "unregistered"> {
      if (
        !message.token || !message.title || !message.body ||
        Object.values(message.data ?? {}).some((v) => typeof v !== "string")
      ) throw new FcmError("invalid_message");
      const token = await accessToken();
      const response = await post(
        `https://fcm.googleapis.com/v1/projects/${project}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            validate_only: validateOnly,
            message: {
              token: message.token,
              notification: { title: message.title, body: message.body },
              data: message.data ?? {},
            },
          }),
        },
      );
      if (response.ok) return validateOnly ? "validated" : "sent";
      if (response.status === 401) cached = undefined;
      const error = await response.json().catch(() => null);
      if (
        response.status === 404 && Array.isArray(error?.error?.details) &&
        error.error.details.some((d: Record<string, unknown> | null) =>
          d?.["@type"] ===
            "type.googleapis.com/google.firebase.fcm.v1.FcmError" &&
          d?.errorCode === "UNREGISTERED"
        )
      ) return "unregistered";
      // No automatic retry: uncertain delivery must not duplicate a notification.
      throw new FcmError(
        "delivery_failed",
        response.status === 429 || response.status >= 500,
      );
    },
  };
}
