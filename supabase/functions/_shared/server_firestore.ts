import { importPKCS8, SignJWT } from "npm:jose@6.1.0";
import { parseFcmCredentials } from "./fcm.ts";

export const documentRoot =
  "projects/boteparroquial/databases/(default)/documents";
export class WorkerError extends Error {
  constructor(readonly code: string, readonly status = 0) {
    super(code);
  }
}
export type ServerDocument = {
  path: string;
  data: Record<string, unknown>;
  updateTime: string;
};
export function encode(value: unknown): Record<string, unknown> {
  if (value == null) return { nullValue: null };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "number" && Number.isSafeInteger(value)) {
    return { integerValue: String(value) };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(encode) } };
  }
  if (typeof value === "object") {
    return {
      mapValue: { fields: encodeFields(value as Record<string, unknown>) },
    };
  }
  throw new WorkerError("invalid_write");
}
function encodeFields(data: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, encode(v)]),
  );
}
function decode(value: unknown): unknown {
  if (!value || typeof value !== "object") {
    throw new WorkerError("invalid_document");
  }
  const v = value as Record<string, unknown>;
  if ("nullValue" in v) return null;
  if ("stringValue" in v) return v.stringValue;
  if ("booleanValue" in v) return v.booleanValue;
  if ("timestampValue" in v) return v.timestampValue;
  if ("integerValue" in v) {
    const n = Number(v.integerValue);
    if (!Number.isSafeInteger(n)) throw new WorkerError("unsafe_integer");
    return n;
  }
  if ("mapValue" in v) {
    return decodeFields(
      (v.mapValue as { fields?: Record<string, unknown> }).fields ?? {},
    );
  }
  if ("arrayValue" in v) {
    return ((v.arrayValue as { values?: unknown[] }).values ?? []).map(decode);
  }
  throw new WorkerError("unsupported_field");
}
function decodeFields(data: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, decode(v)]),
  );
}
export async function digest(value: string): Promise<string> {
  return [
    ...new Uint8Array(
      await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)),
    ),
  ].map((v) => v.toString(16).padStart(2, "0")).join("");
}
export function createServerAuth(credentialsJson: string, request = fetch) {
  const credentials = parseFcmCredentials(credentialsJson);
  let cached: { token: string; until: number } | undefined;
  let pending: Promise<string> | undefined;
  async function refresh() {
    try {
      const seconds = Math.floor(Date.now() / 1000);
      const assertion = await new SignJWT({
        scope: "https://www.googleapis.com/auth/datastore",
      })
        .setProtectedHeader({ alg: "RS256" }).setIssuer(
          credentials.client_email,
        )
        .setAudience("https://oauth2.googleapis.com/token").setIssuedAt(seconds)
        .setExpirationTime(seconds + 3600)
        .sign(await importPKCS8(credentials.private_key, "RS256"));
      const response = await request("https://oauth2.googleapis.com/token", {
        method: "POST",
        redirect: "error",
        signal: AbortSignal.timeout(15000),
        body: new URLSearchParams({
          grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion,
        }),
      });
      const data = await response.json();
      if (
        !response.ok || typeof data.access_token !== "string" ||
        data.token_type !== "Bearer" || !Number.isInteger(data.expires_in) ||
        data.expires_in <= 60 || data.expires_in > 3600
      ) throw new Error();
      cached = {
        token: data.access_token,
        until: Date.now() + (data.expires_in - 60) * 1000,
      };
      return cached.token;
    } catch {
      throw new WorkerError("server_authorization_failed");
    }
  }
  return async () => {
    if (cached && Date.now() < cached.until) return cached.token;
    pending ??= refresh();
    try {
      return await pending;
    } finally {
      pending = undefined;
    }
  };
}
export class ServerFirestore {
  constructor(readonly token: () => Promise<string>, private request = fetch) {}
  private name(path: string) {
    if (
      !/^(groups|users)\//.test(path) ||
      path.split("/").some((p) => !p || p === "." || p === "..")
    ) throw new WorkerError("invalid_path");
    return `${documentRoot}/${path}`;
  }
  async call(method: string, path: string, body?: unknown): Promise<unknown> {
    try {
      const response = await this.request(
        `https://firestore.googleapis.com/v1/${path}`,
        {
          method,
          headers: {
            Authorization: `Bearer ${await this.token()}`,
            "Content-Type": "application/json",
          },
          body: body === undefined ? undefined : JSON.stringify(body),
          redirect: "error",
          signal: AbortSignal.timeout(15000),
        },
      );
      if (!response.ok) {
        throw new WorkerError("firestore_request_failed", response.status);
      }
      return await response.json();
    } catch (e) {
      if (e instanceof WorkerError) throw e;
      throw new WorkerError("firestore_transport_uncertain");
    }
  }
  private parse(raw: unknown, prefix: string): ServerDocument {
    const v = raw as {
      name: string;
      fields?: Record<string, unknown>;
      updateTime: string;
    };
    if (
      typeof v?.name !== "string" ||
      !v.name.startsWith(`${documentRoot}/${prefix}`) ||
      typeof v.updateTime !== "string"
    ) throw new WorkerError("invalid_document");
    return {
      path: v.name.slice(documentRoot.length + 1),
      data: decodeFields(v.fields ?? {}),
      updateTime: v.updateTime,
    };
  }
  async get(path: string): Promise<ServerDocument | null> {
    try {
      const data = await this.call(
        "GET",
        this.name(path).split("/").map(encodeURIComponent).join("/"),
      );
      const doc = this.parse(data, path);
      if (doc.path !== path) throw new WorkerError("foreign_document");
      return doc;
    } catch (e) {
      if (e instanceof WorkerError && e.status === 404) return null;
      throw e;
    }
  }
  async list(path: string, cap = 10000): Promise<ServerDocument[]> {
    const name = path === "groups" ? `${documentRoot}/groups` : this.name(path);
    let page = "";
    const result: ServerDocument[] = [], seen = new Set<string>();
    do {
      const params = new URLSearchParams({ pageSize: "200" });
      if (page) params.set("pageToken", page);
      const data = await this.call(
        "GET",
        `${name.split("/").map(encodeURIComponent).join("/")}?${params}`,
      ) as { documents?: unknown[]; nextPageToken?: string };
      for (const raw of data.documents ?? []) {
        const doc = this.parse(raw, `${path}/`);
        if (doc.path.slice(path.length + 1).includes("/")) {
          throw new WorkerError("foreign_document");
        }
        result.push(doc);
      }
      page = data.nextPageToken ?? "";
      if (
        result.length > cap ||
        (page && (seen.has(page) || result.length >= cap))
      ) throw new WorkerError("read_limit");
      seen.add(page);
    } while (page);
    return result;
  }
  async since(
    groupId: string,
    collection: "auditEvents" | "movements",
    field: string,
    from: Date,
    until: Date,
  ) {
    const parent = this.name(`groups/${groupId}`);
    const rows = await this.call(
      "POST",
      `${parent.split("/").map(encodeURIComponent).join("/")}:runQuery`,
      {
        structuredQuery: {
          from: [{ collectionId: collection }],
          where: {
            compositeFilter: {
              op: "AND",
              filters: [
                {
                  fieldFilter: {
                    field: { fieldPath: field },
                    op: "GREATER_THAN_OR_EQUAL",
                    value: encode(from),
                  },
                },
                {
                  fieldFilter: {
                    field: { fieldPath: field },
                    op: "LESS_THAN_OR_EQUAL",
                    value: encode(until),
                  },
                },
              ],
            },
          },
          orderBy: [{ field: { fieldPath: field }, direction: "ASCENDING" }],
          limit: 501,
        },
      },
    ) as { document?: unknown }[];
    const docs = rows.filter((v) => v.document).map((v) =>
      this.parse(v.document, `groups/${groupId}/${collection}/`)
    );
    if (docs.length > 500) throw new WorkerError("activity_backlog_limit");
    return docs;
  }
  async put(
    path: string,
    data: Record<string, unknown>,
    condition?: { exists: boolean } | { updateTime: string },
  ) {
    if (
      !/^groups\/[^/]+\/(?:(?:notifications|notificationDeliveries|notificationDeviceStates)\/[a-f0-9]{64}|notificationWorker\/state)$/
        .test(path)
    ) {
      throw new WorkerError("write_outside_notification_scope");
    }
    // Reading the group in a read/write transaction makes a concurrent deletion
    // lock conflict with this write. A stale cron list cannot resurrect children.
    const start = await this.call("POST", `${documentRoot}:beginTransaction`, {
      options: { readWrite: {} },
    }) as { transaction?: string };
    if (!start.transaction) throw new WorkerError("missing_transaction");
    const transaction = start.transaction;
    try {
      const groupPath = path.split("/").slice(0, 2).join("/");
      const group = await this.call(
        "GET",
        `${
          this.name(groupPath).split("/").map(encodeURIComponent).join("/")
        }?transaction=${encodeURIComponent(transaction)}`,
      ) as { fields?: Record<string, { booleanValue?: boolean }> };
      if (group.fields?.isActive?.booleanValue !== true) {
        throw new WorkerError("inactive_group");
      }
      return await this.call("POST", `${documentRoot}:commit`, {
        transaction,
        writes: [{
          update: { name: this.name(path), fields: encodeFields(data) },
          ...(condition ? { currentDocument: condition } : {}),
        }],
      });
    } catch (error) {
      await this.call("POST", `${documentRoot}:rollback`, { transaction })
        .catch(() => {});
      throw error;
    }
  }
  async create(path: string, data: Record<string, unknown>): Promise<boolean> {
    try {
      await this.put(path, data, { exists: false });
      return true;
    } catch (e) {
      if (e instanceof WorkerError && [409, 412].includes(e.status)) {
        return false;
      }
      throw e;
    }
  }
}
