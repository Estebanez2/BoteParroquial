import { deepEqual, equal, rejects } from "node:assert/strict";
import {
  createLocalJWKSet,
  exportJWK,
  generateKeyPair,
  SignJWT,
} from "npm:jose@6.1.0";
import { verifyFirebaseToken } from "./firebase.ts";
import { AccessError, createHandler } from "./handler.ts";

const str = (value: string) => ({ stringValue: value });
const member = (uid: string, role: string, status = "active") => ({
  uid: str(uid),
  role: str(role),
  status: str(status),
  personId: str("internal"),
});
type Fields = Record<string, { stringValue?: string; booleanValue?: boolean }>;

function fixture(actorRole = "owner", targetRole = "member") {
  const documents: Record<string, Fields> = {
    "users/actor": { displayName: str("DEMO") },
    "groups/one": { isActive: { booleanValue: true } },
    "groups/one/members/actor": member("actor", actorRole),
    "groups/one/members/other": member("other", targetRole),
    "groups/one/persons/internal": { isActive: { booleanValue: true } },
    "groups/one/persons/inactive": { isActive: { booleanValue: false } },
  };
  const writes: string[] = [];
  const reads: string[] = [];
  const absent = new Set<string>();
  const handler = createHandler({
    verifyToken: async (token) => {
      if (token !== "valid") throw new Error("Invalid token");
      return "actor";
    },
    fetchDocument: async (path, token) => {
      equal(token, "valid");
      reads.push(path);
      if (!documents[path]) throw new AccessError(403);
      return documents[path];
    },
    storage: {
      upload: async (path) => {
        writes.push(path);
      },
      remove: async (path) => {
        writes.push(path);
      },
      download: async (path, version) => {
        reads.push(path);
        if (absent.has(path)) throw new AccessError(404);
        if (version === '"demo"') return new Response(null, { status: 304 });
        return new Response(new Uint8Array([1, 2, 3]), {
          headers: { "Content-Type": "image/png", etag: '"demo"' },
        });
      },
    },
  });
  const call = (data: unknown, token = "valid") =>
    handler(
      new Request("https://example.test/photo-access", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ actorUid: "actor", ...(data as object) }),
      }),
    );
  return { documents, writes, reads, call, absent };
}

Deno.test("Account photo defaults stay group-authorized and support conditional reads", async () => {
  const f = fixture("member");
  f.absent.add("groups/one/members/other/avatar");
  const target = { kind: "member", groupId: "one", uid: "other" };
  const first = await f.call({ action: "readCached", target });
  equal(first.status, 200);
  const data = await first.json();
  equal(data.version, 'account:"demo"');
  equal(data.notModified, false);
  const unchanged = await f.call({
    action: "readCached",
    target,
    ifNoneMatch: data.version,
  });
  deepEqual(await unchanged.json(), {
    notModified: true,
    version: data.version,
  });
  equal(
    (await f.call({
      action: "readCached",
      target: { kind: "account", uid: "other" },
    })).status,
    403,
  );
  f.absent.clear();
  const custom = await f.call({
    action: "readCached",
    target,
    ifNoneMatch: data.version,
  });
  equal((await custom.json()).version, 'member:"demo"');
  f.documents["groups/one/members/actor"] = member(
    "actor",
    "member",
    "inactive",
  );
  equal(
    (await f.call({ action: "readCached", target, ifNoneMatch: data.version }))
      .status,
    403,
  );
});

Deno.test("Firebase JWT: signature, project, expiration and auth_time checked", async () => {
  const pair = await generateKeyPair("RS256");
  const jwk = await exportJWK(pair.publicKey);
  const keys = createLocalJWKSet({
    keys: [{ ...jwk, kid: "test", alg: "RS256" }],
  });
  const now = Math.floor(Date.now() / 1000);
  const sign = (overrides: Record<string, unknown> = {}) =>
    new SignJWT({
      iss: "https://securetoken.google.com/boteparroquial",
      aud: "boteparroquial",
      sub: "actor",
      exp: now + 3600,
      iat: now - 10,
      auth_time: now - 10,
      ...overrides,
    }).setProtectedHeader({ alg: "RS256", kid: "test" }).sign(pair.privateKey);
  equal(await verifyFirebaseToken(await sign(), keys), "actor");
  for (
    const invalid of [
      { aud: "another-project" },
      { iss: "https://untrusted.test" },
      { exp: now - 10 },
      { auth_time: now + 60 },
      { sub: "" },
    ]
  ) {
    const token = await sign(invalid);
    await rejects(() => verifyFirebaseToken(token, keys));
  }
  const signed = await sign();
  const segments = signed.split(".");
  segments[2] = (segments[2][0] === "A" ? "B" : "A") + segments[2].slice(1);
  await rejects(() => verifyFirebaseToken(segments.join("."), keys));
});

Deno.test("Roles: owner, admin and self access follow group permissions", async () => {
  const cases = [
    ["owner", "admin", true],
    ["admin", "member", true],
    ["admin", "admin", false],
    ["admin", "owner", false],
    ["member", "member", false],
  ] as const;
  for (const [actor, other, expected] of cases) {
    const f = fixture(actor, other);
    const response = await f.call({
      action: "access",
      target: {
        kind: "member",
        groupId: "one",
        uid: "other",
      },
    });
    equal(response.status, 200);
    deepEqual(await response.json(), { canRead: true, canEdit: expected });
    const own = await f.call({
      action: "access",
      target: {
        kind: "member",
        groupId: "one",
        uid: "actor",
      },
    });
    equal((await own.json()).canEdit, true);
    const group = await f.call({
      action: "access",
      target: { kind: "group", groupId: "one" },
    });
    equal((await group.json()).canEdit, actor === "owner");
  }
});

Deno.test("No access without verified token, membership or valid scoped target", async () => {
  const f = fixture();
  const group = { kind: "group", groupId: "one" };
  equal(
    (await f.call({ action: "read", target: group }, "forged")).status,
    401,
  );
  equal(f.reads.length, 0);
  equal(
    (await f.call({ action: "read", actorUid: "another", target: group }))
      .status,
    403,
  );
  for (
    const target of [
      { kind: "account", uid: "other" },
      { kind: "group", groupId: "two" },
    ]
  ) equal((await f.call({ action: "read", target })).status, 403);
  for (
    const target of [
      { kind: "group", groupId: "../one" },
      { kind: "member", groupId: "one", uid: "other", role: "owner" },
    ]
  ) equal((await f.call({ action: "upload", target })).status, 400);
  f.documents["groups/one/members/actor"] = member(
    "actor",
    "owner",
    "inactive",
  );
  equal((await f.call({ action: "read", target: group })).status, 403);
  deepEqual(f.writes, []);
});

Deno.test("Writes recheck permission, reject non-images, and never touch another scope", async () => {
  const f = fixture("admin");
  const target = { kind: "member", groupId: "one", uid: "other" };
  // Minimal raster signature fixture: no claim that this decodes as an image.
  const imageBase64 = btoa(
    String.fromCharCode(255, 216, 255, 0, 0, 0, 0, 0, 0, 0, 255, 217),
  );
  equal((await f.call({ action: "upload", target, imageBase64 })).status, 200);
  deepEqual(f.writes, ["groups/one/members/other/avatar"]);
  f.documents["groups/one/members/other"] = member("other", "admin");
  equal((await f.call({ action: "remove", target })).status, 403);
  equal(f.writes.length, 1);
  const mine = { kind: "account", uid: "actor" };
  const svg = btoa("<svg xmlns='http://www.w3.org/2000/svg'></svg>");
  equal(
    (await f.call({ action: "upload", target: mine, imageBase64: svg })).status,
    415,
  );
  equal(
    (await f.call({
      action: "upload",
      target: mine,
      imageBase64: "x".repeat(699053),
    })).status,
    413,
  );
  const read = await f.call({ action: "read", target });
  equal(read.status, 200);
  equal(read.headers.get("Cache-Control"), "no-store");
  equal(read.headers.get("X-Content-Type-Options"), "nosniff");
  await read.arrayBuffer();
});

Deno.test("Internal persons are independent; inactive admin link blocks management", async () => {
  const f = fixture("admin");
  const target = { kind: "person", groupId: "one", personId: "inactive" };
  equal((await f.call({ action: "remove", target })).status, 200);
  deepEqual(f.writes, ["groups/one/persons/inactive/avatar"]);
  f.documents["groups/one/persons/internal"] = {
    isActive: { booleanValue: false },
  };
  const access = await f.call({ action: "access", target });
  deepEqual(await access.json(), { canRead: true, canEdit: false });
  equal((await f.call({ action: "remove", target })).status, 403);
  delete f.documents["groups/one"];
  equal((await f.call({ action: "remove", target })).status, 403);
  equal(f.writes.length, 1);
});
