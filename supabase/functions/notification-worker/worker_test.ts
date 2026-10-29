import { deepStrictEqual, equal } from "node:assert/strict";
import {
  activityNotices,
  GroupAudience,
} from "../_shared/activity_notifications.ts";
import {
  digest,
  type ServerDocument,
  ServerFirestore,
  WorkerError,
} from "../_shared/server_firestore.ts";
import { createWorkerHandler } from "./handler.ts";
import { createNotificationWorker } from "./worker.ts";

class MemoryFirestore extends ServerFirestore {
  docs = new Map<string, ServerDocument>();
  version = 0;
  constructor() {
    super(() => Promise.resolve("unused"));
  }
  seed(path: string, data: Record<string, unknown>) {
    this.docs.set(path, {
      path,
      data: JSON.parse(JSON.stringify(data)),
      updateTime: String(++this.version),
    });
  }
  override get(path: string) {
    return Promise.resolve(structuredClone(this.docs.get(path) ?? null));
  }
  override list(path: string) {
    return Promise.resolve(
      [...this.docs.values()].filter((d) =>
        d.path.startsWith(`${path}/`) &&
        !d.path.slice(path.length + 1).includes("/")
      ).map((d) => structuredClone(d)),
    );
  }
  override since(
    group: string,
    collection: "auditEvents" | "movements",
    field: string,
    from: Date,
    until: Date,
  ) {
    return Promise.resolve(
      [...this.docs.values()].filter((d) =>
        d.path.startsWith(`groups/${group}/${collection}/`) &&
        Date.parse(String(d.data[field])) >= from.getTime() &&
        Date.parse(String(d.data[field])) <= until.getTime()
      ),
    );
  }
  override put(
    path: string,
    data: Record<string, unknown>,
    condition?: { exists: boolean } | { updateTime: string },
  ) {
    const current = this.docs.get(path);
    if (
      condition &&
      (("exists" in condition && condition.exists !== !!current) ||
        ("updateTime" in condition &&
          condition.updateTime !== current?.updateTime))
    ) return Promise.reject(new WorkerError("conflict", 409));
    this.seed(path, data);
    return Promise.resolve({});
  }
}
const now = new Date("2026-10-20T10:05:00Z");
const activation = new Date("2026-10-20T09:00:00Z");
async function fixture() {
  const db = new MemoryFirestore();
  db.seed("groups/g", { isActive: true, timeZone: "Europe/Madrid" });
  db.seed("groups/g/members/alice", {
    uid: "alice",
    role: "owner",
    status: "active",
  });
  db.seed("groups/g/members/bob", {
    uid: "bob",
    role: "member",
    status: "active",
    personId: "p",
  });
  db.seed("groups/g/persons/p", { linkedUid: "bob", isActive: true });
  db.seed("groups/g/movements/income", {
    type: "income",
    status: "active",
    personId: "p",
    amountCents: 1000,
    createdBy: "alice",
    createdAt: "2026-10-20T10:00:00Z",
    updatedAt: "2026-10-20T10:00:00Z",
  });
  const token = "DEMO-long-private-device-token";
  db.seed(`users/bob/pushDevices/${await digest(token)}`, {
    token,
    platform: "android",
  });
  return db;
}

Deno.test("Worker: durable inbox/attempt, concurrent runs and no uncertain push replay", async () => {
  const db = await fixture();
  let sends = 0;
  const worker = createNotificationWorker({
    db,
    startedAt: activation,
    now: () => now,
    readQuotas: () => Promise.reject(new Error("not a reminder date")),
    send: () => {
      sends++;
      return Promise.reject(new Error("uncertain delivery"));
    },
  });
  await Promise.all([worker.run(), worker.run()]);
  equal(sends, 1);
  const inbox = await db.list("groups/g/notifications");
  equal(inbox.length, 1);
  equal(inbox[0].data.recipientUid, "bob");
  equal(
    (await db.list("groups/g/notificationDeliveries"))[0].data.state,
    "uncertain",
  );
  db.seed(inbox[0].path, { ...inbox[0].data, readAt: now.toISOString() });
  const state = (await db.get("groups/g/notificationWorker/state"))!;
  db.seed(state.path, { ...state.data, cursor: activation.toISOString() });
  await worker.run();
  equal(sends, 1);
  equal((await db.get(inbox[0].path))!.data.readAt, now.toISOString());
});

Deno.test("Preferences preserve inbox; revoked access and old activity receive nothing", async () => {
  for (const scenario of ["preference", "revoked", "historical"] as const) {
    const db = await fixture();
    if (scenario === "preference") {
      db.seed("groups/g/members/bob/notificationPreferences/economic", {
        pushEnabled: false,
      });
    }
    if (scenario === "revoked") {
      db.seed("groups/g/members/bob", {
        uid: "bob",
        role: "member",
        status: "inactive",
        personId: "p",
      });
    }
    if (scenario === "historical") {
      const source = (await db.get("groups/g/movements/income"))!;
      db.seed(source.path, {
        ...source.data,
        createdAt: "2025-01-01T00:00:00Z",
      });
    }
    let sends = 0;
    const worker = createNotificationWorker({
      db,
      startedAt: activation,
      now: () => now,
      readQuotas: () => Promise.reject(new Error("unused")),
      send: () => {
        sends++;
        return Promise.resolve("sent");
      },
    });
    await worker.run();
    equal(sends, 0, scenario);
    equal(
      (await db.list("groups/g/notifications")).length,
      scenario === "preference" ? 1 : 0,
      scenario,
    );
  }
});

Deno.test("Activity matrix: current managers, own access, no self-spam or foreign group", async () => {
  const db = await fixture();
  const audience = new GroupAudience(
    "g",
    await db.list("groups/g/members"),
    await db.list("groups/g/persons"),
  );
  const audit = (
    action: string,
    entityId: string,
    before: Record<string, unknown> | null,
    after: Record<string, unknown>,
    actorUid = "bob",
  ) => ({
    path: "groups/g/auditEvents/event",
    updateTime: "1",
    data: { action, entityId, before, after, actorUid },
  });
  equal(
    activityNotices(audit("join.requested", "bob", null, {}), audience)[0]
      .recipientUid,
    "alice",
  );
  equal(
    activityNotices(audit("join.approved", "bob", null, {}, "alice"), audience)
      .find((n) => n.kind === "memberAccepted")?.recipientUid,
    "bob",
  );
  equal(
    activityNotices(
      audit("invitation.changed", "g", {}, { regenerated: true }),
      audience,
    )[0].kind,
    "invitationRegenerated",
  );
  equal(
    activityNotices(
      audit("quota.changed", "24321", null, {}, "alice"),
      audience,
    )[0].recipientUid,
    "bob",
  );
  equal(
    activityNotices(
      audit("member.roleChanged", "bob", { role: "admin" }, { role: "member" }),
      audience,
    )[0].kind,
    "adminLost",
  );
  deepStrictEqual(
    activityNotices(
      audit("member.roleChanged", "bob", { role: "member" }, { role: "admin" }),
      audience,
    ),
    [],
  );
});

Deno.test("UNREGISTERED is quarantined for later notifications without deleting client devices", async () => {
  const db = await fixture();
  const source = (await db.get("groups/g/movements/income"))!;
  db.seed("groups/g/movements/income-two", source.data);
  let sends = 0;
  const worker = createNotificationWorker({
    db,
    startedAt: activation,
    now: () => now,
    readQuotas: () => Promise.reject(new Error("unused")),
    send: () => {
      sends++;
      return Promise.resolve("unregistered");
    },
  });
  await worker.run();
  equal(sends, 1);
  equal((await db.list("groups/g/notifications")).length, 2);
  equal((await db.list("groups/g/notificationDeviceStates")).length, 1);
  equal((await db.list("users/bob/pushDevices")).length, 1);
});

Deno.test("HTTP: secret required before work; no client-selected groups, dates or data", async () => {
  let calls = 0;
  const secret = "DEMO-".repeat(12);
  const handler = createWorkerHandler(secret, () => {
    calls++;
    return Promise.resolve({ processed: 1 });
  });
  equal(
    (await handler(
      new Request("https://example.test", { method: "POST", body: "{}" }),
    )).status,
    401,
  );
  const request = (body: string) =>
    new Request("https://example.test", {
      method: "POST",
      headers: { "x-worker-secret": secret },
      body,
    });
  equal((await handler(request('{"groupId":"foreign"}'))).status, 400);
  equal(calls, 0);
  equal((await handler(request("{}"))).status, 200);
  equal(calls, 1);
});
