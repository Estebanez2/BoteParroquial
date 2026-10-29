import { AccessError, objectPath, type PhotoTarget } from "./handler.ts";
import { firebaseProject } from "./firebase.ts";

const root = `projects/${firebaseProject}/databases/(default)/documents`;
const hash = async (bytes: Uint8Array) =>
  [
    ...new Uint8Array(
      await crypto.subtle.digest("SHA-256", bytes as Uint8Array<ArrayBuffer>),
    ),
  ].map((v) => v.toString(16).padStart(2, "0")).join("");
const encode = (v: unknown): unknown =>
  v === null
    ? { nullValue: null }
    : typeof v === "string"
    ? { stringValue: v }
    : {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(v as Record<string, unknown>).map((
            [k, x],
          ) => [k, encode(x)]),
        ),
      },
    };

export function createPhotoAuditor(request = fetch) {
  return async (
    actorUid: string,
    target: PhotoTarget,
    token: string,
    mode: "upload" | "remove",
    image: Uint8Array | undefined,
    download: (path: string) => Promise<Response>,
  ) => {
    let previous: string | null = null;
    try {
      previous = await hash(
        new Uint8Array(
          await (await download(objectPath(target))).arrayBuffer(),
        ),
      );
    } catch (error) {
      if (!(error instanceof AccessError) || error.status !== 404) throw error;
    }
    const operationId = crypto.randomUUID().replaceAll("-", "");
    const after = {
      operationId,
      mode,
      targetKind: target.kind,
      targetId: target.kind === "group"
        ? target.groupId
        : target.kind === "person"
        ? target.personId
        : target.uid,
      fingerprint: image ? await hash(image) : null,
    };
    const parent = target.kind === "account"
      ? `users/${encodeURIComponent(actorUid)}`
      : `groups/${encodeURIComponent(target.groupId)}`;
    async function event(phase: "request" | "complete") {
      const fields = {
        action: phase === "request"
          ? "photo.changeRequested"
          : "photo.changeCompleted",
        entityType: "photo",
        entityId: after.targetId,
        actorUid,
        before: { fingerprint: previous },
        after,
      };
      const response = await request(
        `https://firestore.googleapis.com/v1/${root}:commit`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            writes: [{
              update: {
                name:
                  `${root}/${parent}/auditEvents/photo-${phase}-${operationId}`,
                fields: Object.fromEntries(
                  Object.entries(fields).map(([k, v]) => [k, encode(v)]),
                ),
              },
              currentDocument: { exists: false },
              updateTransforms: [{
                fieldPath: "createdAt",
                setToServerValue: "REQUEST_TIME",
              }],
            }],
          }),
          redirect: "error",
          signal: AbortSignal.timeout(8000),
        },
      );
      if (!response.ok) {
        throw new AccessError(response.status === 403 ? 403 : 503);
      }
    }
    // Intent survives an uncertain Storage request. Completion is a distinct
    // immutable confirmation, never a claim of a distributed transaction.
    await event("request");
    return () => event("complete");
  };
}
