import { deepStrictEqual, equal } from "node:assert/strict";
import { createLifecycleCleanup, type Fields } from "./handler.ts";
import { createPrefixCleaner } from "./storage.ts";
const now = Date.UTC(2026, 9, 20, 15);
const string = (v: string) => ({ stringValue: v }),
  time = (v: number) => ({ timestampValue: new Date(v).toISOString() });
const call = (body: object) =>
  new Request("https://demo.invalid", {
    method: "POST",
    headers: {
      Authorization: "Bearer DEMO",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
Deno.test("Cleanup group requires locked owner, grace and closed input", async () => {
  const paths: string[] = [];
  let owner = "other";
  const handle = createLifecycleCleanup({
    verify: () => Promise.resolve("alice"),
    now: () => now,
    read: async (path): Promise<Fields> => {
      if (path.startsWith("groups/")) {
        return {
          isActive: { booleanValue: false },
          deletionBy: string(owner),
          deletionStartedAt: time(now - 180001),
        };
      }
      return { status: string("deleting") };
    },
    removePrefix: (prefix) => {
      paths.push(prefix);
      return Promise.resolve(true);
    },
  });
  equal((await handle(call({ action: "group", groupId: "a" }))).status, 403);
  equal(paths.length, 0);
  owner = "alice";
  equal(
    (await handle(call({ action: "group", groupId: "a", prefix: "groups/b/" })))
      .status,
    400,
  );
  equal((await handle(call({ action: "group", groupId: "a" }))).status, 200);
  deepStrictEqual(paths, ["groups/a/"]);
  equal(
    (await handle(new Request("https://demo.invalid", { method: "POST" })))
      .status,
    401,
  );
});
Deno.test("Cleanup account scopes paths to its UID and reads the whole bounded body", async () => {
  const paths: string[] = [];
  const handle = createLifecycleCleanup({
    verify: () => Promise.resolve("alice"),
    now: () => now,
    read: () =>
      Promise.resolve({
        status: string("closing"),
        closingAt: time(now - 30001),
        groupIds: { arrayValue: { values: [string("a"), string("b")] } },
      }),
    removePrefix: (prefix) => {
      paths.push(prefix);
      return Promise.resolve(true);
    },
  });
  const encoder = new TextEncoder();
  const request = new Request("https://demo.invalid", {
    method: "POST",
    headers: {
      Authorization: "Bearer DEMO",
      "Content-Type": "application/json",
    },
    body: new ReadableStream({
      start(c) {
        c.enqueue(encoder.encode('{"action":"acc'));
        c.enqueue(encoder.encode('ount","offset":0}'));
        c.close();
      },
    }),
  });
  const response = await handle(request);
  equal(response.status, 200);
  deepStrictEqual(await response.json(), { complete: true, nextOffset: 2 });
  deepStrictEqual(paths, [
    "accounts/alice/",
    "groups/a/members/alice/",
    "groups/b/members/alice/",
  ]);
  equal(
    (await handle(call({ action: "account", offset: 0, uid: "bob" }))).status,
    400,
  );
});
Deno.test("Prefix cleanup drains pages without skipping or crossing group scope", async () => {
  const keys = new Set([
    ...Array.from({ length: 120 }, (_, i) => `groups/a/persons/p${i}/avatar`),
    "groups/b/cover",
  ]);
  const cleaner = createPrefixCleaner(
    "https://demo.invalid",
    "DEMO-key",
    async (url, init) => {
      const data = JSON.parse(String(init?.body));
      if (String(url).includes("/list/")) {
        equal(data.offset, 0);
        const entries = new Map<string, { name: string; id: string | null }>();
        for (const key of keys) {
          if (key.startsWith(data.prefix)) {
            const suffix = key.slice(data.prefix.length),
              name = suffix.split("/")[0];
            entries.set(name, {
              name,
              id: suffix.includes("/") ? null : "DEMO-id",
            });
          }
        }
        return Response.json(
          [...entries.values()].sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 100),
        );
      }
      for (const key of data.prefixes) {
        equal(key.startsWith("groups/a/"), true);
        keys.delete(key);
      }
      return Response.json({});
    },
  );
  equal(await cleaner("groups/a/"), true);
  deepStrictEqual([...keys], ["groups/b/cover"]);
});
