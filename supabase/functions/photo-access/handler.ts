import { firebaseProject } from "./firebase.ts";

type Role = "owner" | "admin" | "member";
export type PhotoTarget =
  | { kind: "account"; uid: string }
  | { kind: "group"; groupId: string }
  | { kind: "member"; groupId: string; uid: string }
  | { kind: "person"; groupId: string; personId: string };
type Fields = Record<string, { stringValue?: string; booleanValue?: boolean }>;
type Dependencies = {
  verifyToken: (token: string) => Promise<string>;
  fetchDocument: (path: string, token: string) => Promise<Fields>;
  storage: {
    upload: (
      path: string,
      bytes: Uint8Array,
      contentType: string,
    ) => Promise<void>;
    download: (path: string, version?: string) => Promise<Response>;
    remove: (path: string) => Promise<void>;
  };
};

export class AccessError extends Error {
  constructor(readonly status: number) {
    super("Photo access unavailable");
  }
}

function identifier(value: unknown): value is string {
  return typeof value === "string" && value.length > 0 &&
    value.length <= 128 && !/[\/\\\x00-\x1f\x7f]/.test(value) &&
    value !== "." && value !== "..";
}

function parseTarget(input: unknown): PhotoTarget {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new AccessError(400);
  }
  const data = input as Record<string, unknown>;
  const keys = Object.keys(data);
  if (
    data.kind === "account" && identifier(data.uid) &&
    keys.length === 2
  ) return { kind: "account", uid: data.uid };
  if (
    data.kind === "group" && identifier(data.groupId) &&
    keys.length === 2
  ) return { kind: "group", groupId: data.groupId };
  if (
    data.kind === "member" && identifier(data.groupId) &&
    identifier(data.uid) && keys.length === 3
  ) return { kind: "member", groupId: data.groupId, uid: data.uid };
  if (
    data.kind === "person" && identifier(data.groupId) &&
    identifier(data.personId) && keys.length === 3
  ) return { kind: "person", groupId: data.groupId, personId: data.personId };
  // No caller-supplied role/path, person/account synchronization or raw URLs.
  throw new AccessError(400);
}

function memberRole(fields: Fields, uid: string): Role {
  const role = fields.role?.stringValue;
  if (
    fields.uid?.stringValue !== uid ||
    fields.status?.stringValue !== "active" ||
    (role !== "owner" && role !== "admin" && role !== "member")
  ) throw new AccessError(403);
  return role;
}

export async function canEditPhoto(
  actorUid: string,
  target: PhotoTarget,
  token: string,
  read: Dependencies["fetchDocument"],
): Promise<boolean> {
  const part = encodeURIComponent;
  if (target.kind === "account") {
    if (target.uid !== actorUid) throw new AccessError(403);
    await read(`users/${part(actorUid)}`, token);
    return true;
  }
  const base = `groups/${part(target.groupId)}`;
  // Always read the current group and memberships. No role cache or SQL mirror.
  const group = await read(base, token);
  if (group.isActive?.booleanValue !== true) throw new AccessError(403);
  const actor = await read(`${base}/members/${part(actorUid)}`, token);
  const actorRole = memberRole(actor, actorUid);
  if (target.kind === "group") return actorRole === "owner";
  if (target.kind === "person") {
    await read(`${base}/persons/${part(target.personId)}`, token);
    if (actorRole === "owner") return true;
    if (actorRole !== "admin") return false;
    const personId = actor.personId?.stringValue;
    if (!identifier(personId)) return false;
    const person = await read(`${base}/persons/${part(personId)}`, token);
    return person.isActive?.booleanValue === true;
  }
  if (target.uid === actorUid) return true;
  const member = await read(`${base}/members/${part(target.uid)}`, token);
  const targetRole = memberRole(member, target.uid);
  if (actorRole === "owner") return true;
  if (actorRole !== "admin" || targetRole !== "member") return false;
  // Match the existing application's definition of an authorized admin.
  const personId = actor.personId?.stringValue;
  if (!identifier(personId)) return false;
  const person = await read(`${base}/persons/${part(personId)}`, token);
  return person.isActive?.booleanValue === true;
}

export async function fetchDocument(
  path: string,
  token: string,
): Promise<Fields> {
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${firebaseProject}/databases/(default)/documents/${path}`,
    {
      headers: { Authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(8000),
      redirect: "error",
    },
  );
  // End-user Firebase token: Firestore Security Rules remain in force.
  if (response.status === 401) throw new AccessError(401);
  if (response.status === 403 || response.status === 404) {
    throw new AccessError(403);
  }
  if (!response.ok) throw new AccessError(503);
  const document = await response.json();
  if (!document.fields || typeof document.fields !== "object") {
    throw new AccessError(503);
  }
  return document.fields;
}

function reply(status: number, data: object): Response {
  return Response.json(data, {
    status,
    headers: { "Cache-Control": "no-store" },
  });
}

export function createHandler(deps: Dependencies) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return reply(405, { error: "method_not_allowed" });
    }
    const authorization = request.headers.get("Authorization") ?? "";
    if (
      !/^Bearer [^\s]+$/i.test(authorization) || authorization.length > 16384
    ) {
      return reply(401, { error: "unauthenticated" });
    }
    const token = authorization.slice(7);
    let actorUid: string;
    try {
      actorUid = await deps.verifyToken(token);
    } catch {
      return reply(401, { error: "unauthenticated" });
    }
    try {
      const contentType = request.headers.get("Content-Type") ?? "";
      if (!contentType.toLowerCase().startsWith("application/json")) {
        throw new AccessError(415);
      }
      // Read with a hard bound, including chunked requests.
      const reader = request.body?.getReader();
      if (!reader) throw new AccessError(400);
      const chunks: Uint8Array[] = [];
      let size = 0;
      try {
        while (true) {
          const chunk = await reader.read();
          if (chunk.done) break;
          size += chunk.value.byteLength;
          if (size > 720000) {
            await reader.cancel();
            throw new AccessError(413);
          }
          chunks.push(chunk.value);
        }
      } finally {
        reader.releaseLock();
      }
      const bytes = new Uint8Array(size);
      let offset = 0;
      for (const chunk of chunks) {
        bytes.set(chunk, offset);
        offset += chunk.byteLength;
      }
      let input: unknown;
      try {
        input = JSON.parse(new TextDecoder().decode(bytes));
      } catch {
        throw new AccessError(400);
      }
      if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw new AccessError(400);
      }
      const data = input as Record<string, unknown>;
      if (data.actorUid !== actorUid) throw new AccessError(403);
      const action = data.action;
      if (
        !["access", "upload", "read", "readCached", "remove"].includes(
          String(action),
        )
      ) {
        throw new AccessError(400);
      }
      const allowed = action === "upload"
        ? ["action", "actorUid", "target", "imageBase64"]
        : action === "readCached"
        ? ["action", "actorUid", "target", "ifNoneMatch"]
        : ["action", "actorUid", "target"];
      if (Object.keys(data).some((key) => !allowed.includes(key))) {
        throw new AccessError(400);
      }
      const target = parseTarget(data.target);
      const canEdit = await canEditPhoto(
        actorUid,
        target,
        token,
        deps.fetchDocument,
      );
      // Every action authorizes again. An access response is only a UI hint.
      if (action === "access") return reply(200, { canRead: true, canEdit });
      const path = objectPath(target);
      if (action === "read" || action === "readCached") {
        const known = typeof data.ifNoneMatch === "string"
          ? data.ifNoneMatch
          : undefined;
        if (known && (known.length > 512 || /[^\x20-\x7e]/.test(known))) {
          throw new AccessError(400);
        }
        let source: string = target.kind;
        const download = (key: string, kind: string) =>
          deps.storage.download(
            key,
            known?.startsWith(`${kind}:`)
              ? known.slice(kind.length + 1)
              : undefined,
          );
        let response: Response;
        try {
          response = await download(path, source);
        } catch (error) {
          if (
            !(error instanceof AccessError) || error.status !== 404 ||
            target.kind !== "member"
          ) throw error;
          // Group access and target membership were already verified. This is
          // the only route that may read another user's global account image.
          source = "account";
          response = await download(
            objectPath({ kind: "account", uid: target.uid }),
            source,
          );
        }
        if (action === "readCached") {
          if (response.status === 304 && known) {
            return reply(200, { notModified: true, version: known });
          }
          const bytes = new Uint8Array(await response.arrayBuffer());
          const fingerprint = response.headers.get("etag") ??
            Array.from(
              new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)),
            )
              .map((value) => value.toString(16).padStart(2, "0")).join("");
          const version = `${source}:${fingerprint}`;
          if (version === known) {
            return reply(200, { notModified: true, version });
          }
          // Bounded by the private bucket's 512 KiB object limit.
          let binary = "";
          for (let offset = 0; offset < bytes.length; offset += 8192) {
            binary += String.fromCharCode(
              ...bytes.subarray(offset, offset + 8192),
            );
          }
          return reply(200, {
            notModified: false,
            version,
            imageBase64: btoa(binary),
          });
        }
        return new Response(response.body, {
          status: 200,
          headers: {
            "Content-Type": "application/octet-stream",
            "Cache-Control": "no-store",
            "X-Content-Type-Options": "nosniff",
          },
        });
      }
      if (!canEdit) throw new AccessError(403);
      if (action === "remove") {
        await deps.storage.remove(path);
      } else {
        const image = decodeImage(data.imageBase64);
        await deps.storage.upload(path, image.bytes, image.contentType);
      }
      return reply(200, { saved: true });
    } catch (error) {
      const status = error instanceof AccessError ? error.status : 503;
      return reply(status, {
        error: status === 401
          ? "unauthenticated"
          : status === 403
          ? "forbidden"
          : status === 404
          ? "photo_not_found"
          : status >= 500
          ? "temporarily_unavailable"
          : "invalid_request",
      });
    }
  };
}

export function objectPath(target: PhotoTarget): string {
  const part = encodeURIComponent;
  switch (target.kind) {
    case "account":
      return `accounts/${part(target.uid)}/avatar`;
    case "group":
      return `groups/${part(target.groupId)}/cover`;
    case "member":
      return `groups/${part(target.groupId)}/members/${
        part(target.uid)
      }/avatar`;
    case "person":
      return `groups/${part(target.groupId)}/persons/${
        part(target.personId)
      }/avatar`;
  }
}

function decodeImage(
  value: unknown,
): { bytes: Uint8Array; contentType: string } {
  if (typeof value !== "string" || value.length > 699052) {
    throw new AccessError(413);
  }
  let bytes: Uint8Array;
  try {
    bytes = Uint8Array.from(atob(value), (char) => char.charCodeAt(0));
  } catch {
    throw new AccessError(400);
  }
  if (bytes.length < 12 || bytes.length > 524288) throw new AccessError(413);
  const matches = (offset: number, values: number[]) =>
    values.every((value, index) => bytes[offset + index] === value);
  const contentType = matches(0, [0xff, 0xd8, 0xff]) &&
      matches(bytes.length - 2, [0xff, 0xd9])
    ? "image/jpeg"
    : matches(0, [137, 80, 78, 71, 13, 10, 26, 10])
    ? "image/png"
    : matches(0, [82, 73, 70, 70]) && matches(8, [87, 69, 66, 80])
    ? "image/webp"
    : null;
  // Raster types only. No user-selected Content-Type, URLs, SVG or file names.
  // Signature checks restrict the format; they do not fully decode an image.
  if (contentType === null) throw new AccessError(415);
  return { bytes, contentType };
}
