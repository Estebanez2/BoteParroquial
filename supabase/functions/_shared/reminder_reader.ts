import {
  type ReminderSnapshot,
  type ScopedDocument,
} from "./quota_reminders.ts";

// Dedicated future worker only. Never import in photo-access. The caller supplies
// a server OAuth token with reviewed IAM permissions, not a Firebase user JWT.
const base = "https://firestore.googleapis.com/v1/";
const root = "projects/boteparroquial/databases/(default)/documents";
const fields = {
  persons: ["isActive", "linkedUid", "trashedAt"],
  members: ["uid", "role", "status", "personId"],
  quotaRules: ["effectiveFromMonth", "monthlyFeeCents"],
  participationPeriods: ["personId", "firstMonth", "lastMonthInclusive"],
  movements: ["type", "status", "personId", "amountCents", "refund"],
  allocations: ["movementId", "personId", "month", "amountCents", "revision"],
} as const;
export class ReminderReadError extends Error {
  constructor(code: "read_failed" | "invalid_data" | "snapshot_limit") {
    super(code);
  }
}
function invalid(): never {
  throw new ReminderReadError("invalid_data");
}
function segment(value: string): string {
  if (!value || value === "." || value === ".." || value.includes("/")) {
    invalid();
  }
  return encodeURIComponent(value);
}
function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) invalid();
  return value as Record<string, unknown>;
}
function decode(value: unknown): unknown {
  const v = record(value);
  const keys = Object.keys(v);
  if (keys.length !== 1) invalid();
  if ("nullValue" in v && v.nullValue === null) return null;
  if ("stringValue" in v && typeof v.stringValue === "string") {
    return v.stringValue;
  }
  if ("booleanValue" in v && typeof v.booleanValue === "boolean") {
    return v.booleanValue;
  }
  if ("timestampValue" in v && typeof v.timestampValue === "string" &&
      Number.isFinite(Date.parse(v.timestampValue))) {
    return v.timestampValue;
  }
  if (
    "integerValue" in v && typeof v.integerValue === "string" &&
    /^-?(0|[1-9]\d*)$/.test(v.integerValue)
  ) {
    const integer = BigInt(v.integerValue);
    if (
      integer < BigInt(Number.MIN_SAFE_INTEGER) ||
      integer > BigInt(Number.MAX_SAFE_INTEGER)
    ) invalid();
    return Number(integer);
  }
  if ("mapValue" in v) {
    const map = record(v.mapValue);
    return decodeFields(map.fields ?? {});
  }
  // No floats, references or arrays in the selected fields.
  invalid();
}
function decodeFields(value: unknown): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(record(value)).map(([key, v]) => [key, decode(v)]),
  );
}
type ReaderOptions = {
  accessToken: () => Promise<string>;
  fetch?: typeof fetch;
  /** Fail the whole group on overflow; never calculate on a truncated history. */
  maxDocuments?: number;
};

export function createReminderReader(options: ReaderOptions) {
  const request = options.fetch ?? fetch;
  const limit = options.maxDocuments ?? 10000;
  if (!Number.isInteger(limit) || limit < 1 || limit > 10000) invalid();
  return {
    async read(groupId: string): Promise<ReminderSnapshot> {
      const groupPath = `${root}/groups/${segment(groupId)}`;
      const groupName = `${root}/groups/${groupId}`;
      let transaction: string | undefined;
      let documents = 0;
      const deadline = AbortSignal.timeout(45000);
      let token: string;
      try {
        token = await options.accessToken();
        if (typeof token !== "string" || !token) invalid();
      } catch {
        throw new ReminderReadError("read_failed");
      }
      const headers = {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      };
      async function call(
        path: string,
        query?: URLSearchParams,
        body?: unknown,
        optional = false,
      ): Promise<unknown> {
        // URL and paths are assembled locally; responses cannot redirect OAuth.
        try {
          const response = await request(
            `${base}${path}${query ? `?${query}` : ""}`,
            {
              method: body === undefined ? "GET" : "POST",
              headers,
              body: body === undefined ? undefined : JSON.stringify(body),
              redirect: "error",
              signal: AbortSignal.any([deadline, AbortSignal.timeout(15000)]),
            },
          );
          if (optional && response.status === 404) return null;
          if (!response.ok) throw new ReminderReadError("read_failed");
          return await response.json();
        } catch {
          // Do not include credentials, URLs, bodies, financial data or SDK errors.
          throw new ReminderReadError("read_failed");
        }
      }
      function query(mask: readonly string[]) {
        const result = new URLSearchParams({ transaction: transaction! });
        for (const field of mask) result.append("mask.fieldPaths", field);
        return result;
      }
      function document(
        raw: unknown,
        expectedPath: string,
      ): Record<string, unknown> {
        const data = record(raw);
        if (data.name !== expectedPath) invalid();
        if (++documents > limit) throw new ReminderReadError("snapshot_limit");
        return decodeFields(data.fields ?? {});
      }
      async function list(
        collection: keyof typeof fields,
      ): Promise<ScopedDocument[]> {
        const prefix = `${groupName}/${collection}/`;
        const path = `${groupPath}/${collection}`;
        const all: ScopedDocument[] = [];
        const tokens = new Set<string>();
        let page = "";
        do {
          const params = query(fields[collection]);
          params.set("pageSize", "200");
          if (page) params.set("pageToken", page);
          const data = record(await call(path, params));
          if (data.documents !== undefined && !Array.isArray(data.documents)) {
            invalid();
          }
          for (const item of (data.documents ?? []) as unknown[]) {
            const name = record(item).name;
            if (typeof name !== "string" || !name.startsWith(prefix)) invalid();
            const id = name.slice(prefix.length);
            segment(id); // Must be one exact document below this collection.
            all.push({ id, groupId, data: document(item, name) });
          }
          if (
            data.nextPageToken !== undefined &&
            typeof data.nextPageToken !== "string"
          ) invalid();
          page = (data.nextPageToken as string | undefined) ?? "";
          if (page && tokens.has(page)) invalid();
          if (page && documents >= limit) {
            throw new ReminderReadError("snapshot_limit");
          }
          tokens.add(page);
        } while (page);
        return all;
      }
      try {
        const begun = record(
          await call(`${root}:beginTransaction`, undefined, {
            options: { readOnly: {} },
          }),
        );
        if (typeof begun.transaction !== "string" || !begun.transaction) {
          invalid();
        }
        transaction = begun.transaction;
        const group = document(
          await call(groupPath, query(["isActive", "timeZone"])),
          `${root}/groups/${groupId}`,
        );
        if (
          typeof group.isActive !== "boolean" ||
          typeof group.timeZone !== "string"
        ) invalid();
        // Sequential requests keep bounds deterministic and share one snapshot.
        const persons = (await list("persons")).filter((person) =>
          person.data.trashedAt == null
        ), members = await list("members");
        const rules = await list("quotaRules"),
          periods = await list("participationPeriods");
        const movements = await list("movements"),
          allocations = await list("allocations");
        const preferences: ScopedDocument[] = [];
        for (const member of members) {
          const path = `${groupPath}/members/${
            segment(member.id)
          }/notificationPreferences/reminders`;
          const raw = await call(
            path,
            query(["quotaPushEnabled"]),
            undefined,
            true,
          );
          if (raw !== null) {
            preferences.push({
              id: member.id,
              groupId,
              data: document(
                raw,
                `${root}/groups/${groupId}/members/${member.id}/notificationPreferences/reminders`,
              ),
            });
          }
        }
        return {
          groupId,
          group: { isActive: group.isActive, timeZone: group.timeZone },
          persons,
          members,
          rules,
          periods,
          movements,
          allocations,
          preferences,
        };
      } finally {
        if (transaction) {
          // Best effort release; transaction expiry also releases read resources.
          await call(`${root}:rollback`, undefined, { transaction }).catch(
            () => {},
          );
        }
      }
    },
  };
}
