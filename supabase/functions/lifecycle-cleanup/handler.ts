import { AccessError, canEditPhoto } from "../photo-access/handler.ts";

type Value = {
  stringValue?: string;
  booleanValue?: boolean;
  integerValue?: string;
  timestampValue?: string;
  arrayValue?: { values?: Value[] };
};
export type Fields = Record<string, Value>;
type Dependencies = {
  verify: (token: string) => Promise<string>;
  read: (path: string, token: string) => Promise<Fields | null>;
  removePrefix: (prefix: string) => Promise<boolean>;
  now?: () => number;
};
const id = (v: unknown): v is string =>
  typeof v === "string" && /^[a-zA-Z0-9_-]{1,128}$/.test(v);

export function createLifecycleCleanup(deps: Dependencies) {
  return async (request: Request): Promise<Response> => {
    const response = (status: number, body: object) =>
      Response.json(body, { status, headers: { "Cache-Control": "no-store" } });
    if (request.method !== "POST") {
      return response(405, { error: "method_not_allowed" });
    }
    const authorization = request.headers.get("Authorization") ?? "";
    if (!/^Bearer [^\s]{1,16384}$/i.test(authorization)) {
      return response(401, { error: "unauthenticated" });
    }
    try {
      const token = authorization.slice(7);
      let uid: string;
      try {
        uid = await deps.verify(token);
      } catch {
        throw new AccessError(401);
      }
      if (!id(uid)) throw new AccessError(401);
      if (
        !request.headers.get("Content-Type")?.startsWith("application/json")
      ) throw new AccessError(415);
      const reader = request.body?.getReader();
      if (!reader) throw new AccessError(400);
      let size = 0;
      const chunks: Uint8Array[] = [];
      try {
        while (true) {
          const chunk = await reader.read();
          if (chunk.done) break;
          size += chunk.value.byteLength;
          if (size > 2048) {
            await reader.cancel();
            throw new AccessError(400);
          }
          chunks.push(chunk.value);
        }
      } finally {
        reader.releaseLock();
      }
      const bytes = new Uint8Array(size);
      let position = 0;
      for (const chunk of chunks) {
        bytes.set(chunk, position);
        position += chunk.length;
      }
      let input: Record<string, unknown>;
      try {
        input = JSON.parse(new TextDecoder().decode(bytes));
      } catch {
        throw new AccessError(400);
      }
      if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw new AccessError(400);
      }
      const now = deps.now?.() ?? Date.now();
      if (
        input.action === "group" && Object.keys(input).length === 2 &&
        id(input.groupId)
      ) {
        const group = await deps.read(`groups/${input.groupId}`, token);
        const task = await deps.read(
          `users/${uid}/groupDeletionTasks/${input.groupId}`,
          token,
        );
        if (
          group?.isActive?.booleanValue !== false ||
          group.deletionBy?.stringValue !== uid ||
          task?.status?.stringValue !== "deleting"
        ) throw new AccessError(403);
        const started = Date.parse(
          group.deletionStartedAt?.timestampValue ?? "",
        );
        if (!Number.isFinite(started) || now < started + 180000) {
          throw new AccessError(409);
        }
        return response(200, {
          complete: await deps.removePrefix(`groups/${input.groupId}/`),
        });
      }
      if (
        input.action === "person" && Object.keys(input).length === 3 &&
        id(input.groupId) && id(input.personId)
      ) {
        const target = {
          kind: "person" as const,
          groupId: input.groupId,
          personId: input.personId,
        };
        const read = async (path: string, token: string) => {
          const doc = await deps.read(path, token);
          if (!doc) throw new AccessError(403);
          return doc;
        };
        if (!await canEditPhoto(uid, target, token, read, true)) {
          throw new AccessError(403);
        }
        const person = await deps.read(
          `groups/${input.groupId}/persons/${input.personId}`,
          token,
        );
        // Rules checked the ten-day server deadline before this intent existed.
        if (
          !person || !person.purgingAt?.timestampValue ||
          person.firstMovementId?.stringValue ||
          person.historyGuardVersion?.integerValue !== "1" ||
          person.linkedUid?.stringValue ||
          person.lastParticipationPeriodId?.stringValue
        ) throw new AccessError(403);
        return response(200, {
          complete: await deps.removePrefix(
            `groups/${input.groupId}/persons/${input.personId}/`,
          ),
        });
      }
      if (
        input.action === "account" && Object.keys(input).length === 2 &&
        Number.isInteger(input.offset) && Number(input.offset) >= 0
      ) {
        const task = await deps.read(
          `users/${uid}/accountLifecycle/current`,
          token,
        );
        const started = Date.parse(task?.closingAt?.timestampValue ?? "");
        if (
          task?.status?.stringValue !== "closing" ||
          !Number.isFinite(started) || now < started + 30000
        ) throw new AccessError(409);
        const groups = (task.groupIds?.arrayValue?.values ?? []).map((v) =>
          v.stringValue
        );
        if (groups.length > 1000 || groups.some((v) => !id(v))) {
          throw new AccessError(403);
        }
        const offset = Number(input.offset);
        if (offset > groups.length) throw new AccessError(400);
        if (!await deps.removePrefix(`accounts/${uid}/`)) {
          return response(200, { complete: false, nextOffset: offset });
        }
        const end = Math.min(offset + 20, groups.length);
        for (let index = offset; index < end; index++) {
          if (
            !await deps.removePrefix(`groups/${groups[index]}/members/${uid}/`)
          ) return response(200, { complete: false, nextOffset: index });
        }
        return response(200, {
          complete: end === groups.length,
          nextOffset: end,
        });
      }
      throw new AccessError(400);
    } catch (error) {
      return response(error instanceof AccessError ? error.status : 503, {
        error: "cleanup_not_confirmed",
      });
    }
  };
}

export async function readLifecycleDocument(
  path: string,
  token: string,
): Promise<Fields | null> {
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/boteparroquial/databases/(default)/documents/${path}`,
    {
      headers: { Authorization: `Bearer ${token}` },
      redirect: "error",
      signal: AbortSignal.timeout(8000),
    },
  );
  if (response.status === 404) return null;
  if (!response.ok) throw new AccessError(response.status === 403 ? 403 : 503);
  return (await response.json()).fields;
}
