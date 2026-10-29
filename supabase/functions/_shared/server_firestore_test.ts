import { deepStrictEqual, equal, throws } from "node:assert/strict";
import { exportPKCS8, generateKeyPair, jwtVerify } from "npm:jose@6.1.0";
import {
  createServerAuth,
  encode,
  ServerFirestore,
  WorkerError,
} from "./server_firestore.ts";

Deno.test("Server OAuth scope, cache and conditional immutable creation", async () => {
  const { privateKey, publicKey } = await generateKeyPair("RS256", {
    extractable: true,
  });
  const credentials = JSON.stringify({
    type: "service_account",
    project_id: "boteparroquial",
    client_email: "demo@boteparroquial.iam.gserviceaccount.com",
    private_key: await exportPKCS8(privateKey),
  });
  let oauth = 0, writes = 0;
  const token = createServerAuth(credentials, async (_url, init) => {
    oauth++;
    const body = init?.body as URLSearchParams;
    const { payload } = await jwtVerify(body.get("assertion")!, publicKey);
    equal(payload.scope, "https://www.googleapis.com/auth/datastore");
    equal(payload.aud, "https://oauth2.googleapis.com/token");
    return Response.json({
      access_token: "DEMO-OAuth",
      token_type: "Bearer",
      expires_in: 3600,
    });
  });
  const db = new ServerFirestore(token, async (url, init) => {
    equal(new Headers(init?.headers).get("Authorization"), "Bearer DEMO-OAuth");
    equal(init?.redirect, "error");
    equal(
      String(url).startsWith(
        "https://firestore.googleapis.com/v1/projects/boteparroquial/",
      ),
      true,
    );
    if (init?.method === "GET") {
      if (String(url).includes("?transaction=")) {
        return Response.json({ fields: { isActive: { booleanValue: true } } });
      }
      return Response.json({}, { status: 404 });
    }
    if (String(url).endsWith(":beginTransaction")) {
      return Response.json({ transaction: "DEMO-transaction" });
    }
    if (String(url).endsWith(":rollback")) return Response.json({});
    writes++;
    const body = await new Response(init?.body).json();
    equal(body.transaction, "DEMO-transaction");
    deepStrictEqual(body.writes[0].currentDocument, { exists: false });
    equal(body.writes[0].update.fields.readAt.nullValue, null);
    return Response.json({}, { status: 409 });
  });
  equal(await db.get("groups/qa"), null);
  equal(
    await db.create(`groups/qa/notifications/${"a".repeat(64)}`, {
      readAt: null,
    }),
    false,
  );
  equal(writes, 1);
  equal(oauth, 1);
  throws(() => encode(1.5), WorkerError);
});

Deno.test("Server refuses stale worker writes to a locked group", async () => {
  let commits = 0;
  const db = new ServerFirestore(() => Promise.resolve("DEMO"), async (url) => {
    if (String(url).endsWith(":beginTransaction")) {
      return Response.json({ transaction: "DEMO" });
    }
    if (String(url).endsWith(":commit")) commits++;
    if (String(url).includes("?transaction=")) {
      return Response.json({ fields: { isActive: { booleanValue: false } } });
    }
    return Response.json({});
  });
  await db.create(`groups/qa/notifications/${"a".repeat(64)}`, { readAt: null })
    .then(() => {
      throw new Error("unexpected write");
    }, (error) => equal(error.code, "inactive_group"));
  equal(commits, 0);
});
