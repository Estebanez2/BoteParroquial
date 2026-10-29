import { equal, rejects, throws } from "node:assert/strict";
import { exportPKCS8, generateKeyPair, jwtVerify } from "npm:jose@6.1.0";
import { createFcmSender, FcmError, parseFcmCredentials } from "./fcm.ts";

const { privateKey, publicKey } = await generateKeyPair("RS256", {
  extractable: true,
});
const credentials = {
  type: "service_account",
  project_id: "boteparroquial",
  client_email: "demo@boteparroquial.iam.gserviceaccount.com",
  private_key: await exportPKCS8(privateKey),
};
const message = {
  token: "DEMO-device",
  title: "DEMO",
  body: "No real delivery",
};

Deno.test("OAuth firmado, scope limitado, caché y validación por defecto", async () => {
  let oauth = 0, deliveries = 0, now = Date.now();
  const sender = createFcmSender(JSON.stringify(credentials), {
    now: () => now,
    fetch: async (url, init) => {
      if (url === "https://oauth2.googleapis.com/token") {
        oauth++;
        const body = init?.body as URLSearchParams;
        const { payload } = await jwtVerify(
          body.get("assertion") ?? "",
          publicKey,
          {
            issuer: credentials.client_email,
            audience: url,
            currentDate: new Date(now),
          },
        );
        equal(
          payload.scope,
          "https://www.googleapis.com/auth/firebase.messaging",
        );
        return Response.json({
          access_token: "DEMO-access",
          expires_in: 3600,
          token_type: "Bearer",
        });
      }
      equal(
        url,
        "https://fcm.googleapis.com/v1/projects/boteparroquial/messages:send",
      );
      equal(
        new Headers(init?.headers).get("Authorization"),
        "Bearer DEMO-access",
      );
      equal(JSON.parse(init?.body as string).validate_only, true);
      deliveries++;
      return Response.json({});
    },
  });
  equal(await sender.send(message), "validated");
  await Promise.all([sender.send(message), sender.send(message)]);
  equal(oauth, 1);
  now += 3600000;
  equal(await sender.send(message), "validated");
  equal(oauth, 2);
  equal(deliveries, 4);
});

Deno.test("Token eliminado exige error FCM preciso; no reintenta fallos", async () => {
  let calls = 0, status = 404, detail = true;
  const sender = createFcmSender(JSON.stringify(credentials), {
    fetch: async (url) => {
      if (url === "https://oauth2.googleapis.com/token") {
        return Response.json({
          access_token: "DEMO-access",
          expires_in: 3600,
          token_type: "Bearer",
        });
      }
      calls++;
      return Response.json({
        error: {
          details: detail
            ? [null, {
              "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError",
              errorCode: "UNREGISTERED",
            }]
            : [],
        },
      }, { status });
    },
  });
  equal(await sender.send(message), "unregistered");
  detail = false;
  await rejects(
    () => sender.send(message),
    (e) => e instanceof FcmError && !e.retryable,
  );
  status = 503;
  await rejects(
    () => sender.send(message),
    (e) =>
      e instanceof FcmError && e.retryable && e.message === "delivery_failed",
  );
  equal(calls, 3);
});

Deno.test("Rechaza proyecto/endpoint ajenos y no expone claves en errores", async () => {
  for (
    const value of [
      "DEMO-private-content",
      JSON.stringify({ ...credentials, project_id: "foreign" }),
      JSON.stringify({
        ...credentials,
        token_uri: "https://foreign.example/token",
      }),
    ]
  ) {
    throws(
      () => parseFcmCredentials(value),
      (e) =>
        e instanceof FcmError && e.message === "invalid_server_credentials",
    );
  }
  let calls = 0;
  const sender = createFcmSender(JSON.stringify(credentials), {
    fetch: () => {
      calls++;
      throw new Error("DEMO-sensitive-network-details");
    },
  });
  await rejects(
    () => sender.send(message),
    (e) => e instanceof FcmError && e.message === "transport_unavailable",
  );
  equal(calls, 1);
});
