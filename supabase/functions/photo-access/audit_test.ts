import { deepStrictEqual, equal, rejects } from "node:assert/strict";
import { createPhotoAuditor } from "./audit.ts";
import { AccessError, createHandler } from "./handler.ts";

Deno.test("Photo audit persists intent and a distinct confirmation with server time", async () => {
  const writes: Record<string, unknown>[] = [];
  const audit = createPhotoAuditor(async (_url, init) => {
    const body = JSON.parse(String(init?.body));
    writes.push(body.writes[0]);
    return Response.json({});
  });
  const done = await audit(
    "alice",
    { kind: "member", groupId: "a", uid: "bob" },
    "DEMO",
    "upload",
    new Uint8Array([1, 2, 3]),
    () => Promise.reject(new AccessError(404)),
  );
  equal(writes.length, 1);
  const request = writes[0] as {
    update: { name: string };
    updateTransforms: unknown;
  };
  equal(
    request.update.name.includes("groups/a/auditEvents/photo-request-"),
    true,
  );
  deepStrictEqual(request.updateTransforms, [{
    fieldPath: "createdAt",
    setToServerValue: "REQUEST_TIME",
  }]);
  await done();
  equal(writes.length, 2);
  const failed = createPhotoAuditor(() =>
    Promise.resolve(Response.json({}, { status: 403 }))
  );
  await rejects(() =>
    failed(
      "alice",
      { kind: "account", uid: "alice" },
      "DEMO",
      "remove",
      undefined,
      () => Promise.reject(new AccessError(404)),
    )
  );
});
Deno.test("Storage failure leaves only an intent, never a false completion", async () => {
  const steps: string[] = [];
  const handler = createHandler({
    verifyToken: () => Promise.resolve("alice"),
    fetchDocument: () =>
      Promise.resolve({ displayName: { stringValue: "Ana" } }),
    audit: () => {
      steps.push("intent");
      return Promise.resolve(() => {
        steps.push("complete");
        return Promise.resolve();
      });
    },
    storage: {
      download: () => Promise.reject(new AccessError(404)),
      remove: () => Promise.resolve(),
      upload: () => {
        steps.push("upload");
        throw new AccessError(503);
      },
    },
  });
  const bytes = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 0]);
  const response = await handler(
    new Request("https://demo.invalid", {
      method: "POST",
      headers: {
        Authorization: "Bearer DEMO",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        action: "upload",
        actorUid: "alice",
        target: { kind: "account", uid: "alice" },
        imageBase64: btoa(String.fromCharCode(...bytes)),
      }),
    }),
  );
  equal(response.status, 503);
  deepStrictEqual(steps, ["intent", "upload"]);
});
