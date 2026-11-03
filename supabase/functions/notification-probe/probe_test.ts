import { equal } from "node:assert/strict";
import { digest, type ServerDocument } from "../_shared/server_firestore.ts";
import { createNotificationProbe } from "./probe.ts";

Deno.test("Explicit tests: dated, latest device, durable once, revoked session and uncertain send", async () => {
  const docs = new Map<string, ServerDocument>();
  const seed = (path: string, data: Record<string, unknown>) =>
    docs.set(path, { path, data, updateTime: "1" });
  seed("groups/g", { isActive: true });
  seed("groups/g/members/u", { status: "active" });
  const old = "old-private-token-123456", fresh = "new-private-token-123456";
  seed(`users/u/pushDevices/${await digest(old)}`, {
    token: old,
    updatedAt: "2026-11-02T00:00:00Z",
  });
  const freshPath = `users/u/pushDevices/${await digest(fresh)}`;
  seed(freshPath, { token: fresh, updatedAt: "2026-11-03T00:00:00Z" });
  const db = {
    get: (p: string) => Promise.resolve(docs.get(p) ?? null),
    list: (p: string) =>
      Promise.resolve(
        [...docs.values()].filter((d) => d.path.startsWith(p + "/")),
      ),
    create: (p: string, d: Record<string, unknown>) => {
      if (docs.has(p)) return Promise.resolve(false);
      seed(p, d);
      return Promise.resolve(true);
    },
    put: (p: string, d: Record<string, unknown>) => {
      seed(p, d);
      return Promise.resolve(undefined);
    },
  };
  let date = new Date("2026-11-03T16:59:00Z"), sent = 0;
  const run = createNotificationProbe({
    db,
    groupId: "g",
    uid: "u",
    times: ["2026-11-03T17:00:00Z", "2026-11-03T19:00:00Z"],
    now: () => date,
    send: (m) => {
      equal(m.token, fresh);
      sent++;
      throw new Error("uncertain");
    },
  });
  await run();
  equal(sent, 0);
  date = new Date("2026-11-03T17:00:05Z");
  await Promise.all([run(), run()]);
  equal(sent, 1);
  await run();
  equal(sent, 1);
  date = new Date("2026-11-03T19:00:05Z");
  docs.delete(freshPath);
  docs.delete(`users/u/pushDevices/${await digest(old)}`);
  await run();
  equal(sent, 1);
  seed(freshPath, { token: fresh, updatedAt: "2026-11-03T19:00:00Z" });
  seed("groups/g/members/u", { status: "inactive" });
  await run();
  equal(sent, 1);
  seed("groups/g/members/u", { status: "active" });
  date = new Date("2026-11-04T17:00:00Z");
  await run();
  equal(sent, 1);
});
