import {
  activityNotices,
  GroupAudience,
  type Notice,
} from "../_shared/activity_notifications.ts";
import { createReminderReader } from "../_shared/reminder_reader.ts";
import {
  prepareQuotaReminders,
  reminderWindow,
} from "../_shared/quota_reminders.ts";
import {
  digest,
  type ServerDocument,
  ServerFirestore,
  WorkerError,
} from "../_shared/server_firestore.ts";
import type { FcmMessage } from "../_shared/fcm.ts";

export type WorkerDependencies = {
  db: ServerFirestore;
  readQuotas: ReturnType<typeof createReminderReader>["read"];
  send: (message: FcmMessage) => Promise<"sent" | "validated" | "unregistered">;
  startedAt: Date;
  now?: () => Date;
};
export function createNotificationWorker(deps: WorkerDependencies) {
  const db = deps.db, now = deps.now ?? (() => new Date());
  if (!Number.isFinite(deps.startedAt.getTime())) {
    throw new WorkerError("invalid_activation");
  }
  async function audience(groupId: string) {
    if ((await db.get(`groups/${groupId}`))?.data.isActive !== true) {
      return null;
    }
    return new GroupAudience(
      groupId,
      await db.list(`groups/${groupId}/members`, 500),
      await db.list(`groups/${groupId}/persons`, 2000),
    );
  }
  async function currentActivity(groupId: string, source: ServerDocument) {
    const scope = await audience(groupId);
    const current = await db.get(source.path);
    if (current?.path.includes("/movements/")) {
      const timestamp = current.data.status === "cancelled"
        ? current.data.cancelledAt
        : current.data.createdAt;
      if (
        !Number.isFinite(Date.parse(String(timestamp))) ||
        Date.parse(String(timestamp)) < deps.startedAt.getTime()
      ) return [];
    }
    if (
      current?.data.action === "join.requested" &&
      (await db.get(`groups/${groupId}/joinRequests/${current.data.entityId}`))
          ?.data.status !== "pending"
    ) return [];
    return scope && current ? activityNotices(current, scope) : [];
  }
  async function currentReminder(groupId: string): Promise<Notice[]> {
    const snapshot = await deps.readQuotas(groupId);
    return (prepareQuotaReminders(snapshot, now())?.notifications ?? []).map((
      n,
    ) => ({
      sourceKey: n.sourceKey,
      recipientUid: n.recipientUid,
      kind: n.kind,
      category: "reminders",
      title: n.title,
      body: n.body,
      audience: n.kind === "unlinkedQuotaSummary" ? "manager" : "member",
    }));
  }
  async function allowed(groupId: string, notice: Notice) {
    const scope = await audience(groupId);
    return scope !== null && scope.active(notice.recipientUid) &&
      (notice.audience !== "manager" || scope.manager(notice.recipientUid));
  }
  async function pushEnabled(groupId: string, notice: Notice) {
    const doc = await db.get(
      `groups/${groupId}/members/${notice.recipientUid}/notificationPreferences/${notice.category}`,
    );
    const field = notice.category === "reminders"
      ? "quotaPushEnabled"
      : "pushEnabled";
    return doc === null || doc.data[field] === true;
  }
  async function publish(
    groupId: string,
    notice: Notice,
    refresh: () => Promise<Notice[]>,
  ) {
    if (
      !(await refresh()).some((n) => n.sourceKey === notice.sourceKey) ||
      !await allowed(groupId, notice)
    ) return;
    const id = await digest(notice.sourceKey);
    const path = `groups/${groupId}/notifications/${id}`;
    await db.create(path, {
      recipientUid: notice.recipientUid,
      kind: notice.kind,
      title: notice.title,
      body: notice.body,
      createdAt: now(),
      readAt: null,
      category: notice.category,
      sourceKey: notice.sourceKey,
    });
    // A failed create can be a previous identical operation, never overwrite readAt.
    const stored = await db.get(path);
    if (
      stored?.data.sourceKey !== notice.sourceKey ||
      stored.data.recipientUid !== notice.recipientUid
    ) throw new WorkerError("notification_identity_conflict");
    if (!await pushEnabled(groupId, notice)) return;
    const devices = await db.list(
      `users/${notice.recipientUid}/pushDevices`,
      50,
    );
    const seen = new Set<string>();
    for (const device of devices) {
      const token = device.data.token;
      if (typeof token !== "string" || token.length < 16 || seen.has(token)) {
        continue;
      }
      seen.add(token);
      const hash = await digest(token);
      if (device.path !== `users/${notice.recipientUid}/pushDevices/${hash}`) {
        continue;
      }
      const invalidDevice =
        `groups/${groupId}/notificationDeviceStates/${await digest(
          JSON.stringify([notice.recipientUid, hash]),
        )}`;
      if ((await db.get(invalidDevice))?.data.state === "unregistered") {
        continue;
      }
      // Recheck ownership, roles, obligation/event and preference before each delivery.
      if (
        !(await refresh()).some((n) => n.sourceKey === notice.sourceKey) ||
        !await allowed(groupId, notice) ||
        !await pushEnabled(groupId, notice) ||
        (await db.get(device.path))?.data.token !== token
      ) continue;
      const delivery = `groups/${groupId}/notificationDeliveries/${await digest(
        JSON.stringify([id, hash]),
      )}`;
      if (
        !await db.create(delivery, {
          notificationId: id,
          recipientUid: notice.recipientUid,
          tokenHash: hash,
          state: "attempting",
          createdAt: now(),
          updatedAt: now(),
        })
      ) continue;
      // Durable claim precedes the network call. A crash/timeout never replays this
      // token: inbox remains, avoiding duplicate uncertain pushes (D097).
      let state = "uncertain";
      try {
        state = await deps.send({
          token,
          title: notice.title,
          body: notice.body,
          data: { groupId, recipientUid: notice.recipientUid },
        });
      } catch { /* No automatic retry of an uncertain delivery. */ }
      if (state === "unregistered") {
        await db.create(invalidDevice, {
          recipientUid: notice.recipientUid,
          tokenHash: hash,
          state: "unregistered",
          createdAt: now(),
        });
      }
      const claim = await db.get(delivery);
      if (claim) {
        await db.put(delivery, { ...claim.data, state, updatedAt: now() }, {
          updateTime: claim.updateTime,
        });
      }
    }
  }
  return {
    async run() {
      const started = now(), owner = crypto.randomUUID();
      let processed = 0, failed = 0;
      const groups = await db.list("groups", 50);
      for (const group of groups) {
        if (now().getTime() - started.getTime() > 100000) break;
        if (group.data.isActive !== true) continue;
        const groupId = group.path.split("/")[1];
        const statePath = `groups/${groupId}/notificationWorker/state`;
        let acquired = false;
        try {
          const previous = await db.get(statePath);
          if (Date.parse(String(previous?.data.leaseUntil)) > now().getTime()) {
            continue;
          }
          const initial = {
            ...(previous?.data ?? {}),
            owner,
            leaseUntil: new Date(now().getTime() + 150000),
          };
          await db.put(
            statePath,
            initial,
            previous ? { updateTime: previous.updateTime } : { exists: false },
          );
          acquired = true;
          const cursor = new Date(
            String(previous?.data.cursor ?? deps.startedAt.toISOString()),
          );
          if (!Number.isFinite(cursor.getTime())) {
            throw new WorkerError("invalid_cursor");
          }
          const cutoff = new Date(now().getTime() - 5000);
          if (cursor <= cutoff) {
            const from = new Date(
              Math.max(deps.startedAt.getTime(), cursor.getTime() - 1000),
            );
            const sources = [
              ...await db.since(
                groupId,
                "auditEvents",
                "createdAt",
                from,
                cutoff,
              ),
              ...await db.since(
                groupId,
                "movements",
                "updatedAt",
                from,
                cutoff,
              ),
            ];
            for (const source of sources) {
              const refresh = () => currentActivity(groupId, source);
              for (const notice of await refresh()) {
                await publish(groupId, notice, refresh);
              }
            }
          }
          const window = reminderWindow(now(), String(group.data.timeZone));
          const reminderKey = window ? `${window.month}:${window.stage}` : null;
          if (reminderKey && previous?.data.lastReminder !== reminderKey) {
            const refresh = () => currentReminder(groupId);
            for (const notice of await refresh()) {
              await publish(groupId, notice, refresh);
            }
          }
          const current = await db.get(statePath);
          if (!current || current.data.owner !== owner) {
            throw new WorkerError("lease_lost");
          }
          await db.put(statePath, {
            cursor: cursor > cutoff
              ? cursor.toISOString()
              : cutoff.toISOString(),
            lastReminder: reminderKey ?? previous?.data.lastReminder ?? null,
            leaseUntil: now(),
            owner: null,
            updatedAt: now(),
          }, { updateTime: current.updateTime });
          processed++;
        } catch (e) {
          // No unredacted exception, UID, token or financial payload in logs.
          failed++;
          if (acquired) {
            const state = await db.get(statePath).catch(() => null);
            if (state?.data.owner === owner) {
              await db.put(statePath, {
                ...state.data,
                owner: null,
                leaseUntil: now(),
                updatedAt: now(),
              }, { updateTime: state.updateTime }).catch(() => {});
            }
          } else if (
            e instanceof WorkerError && [409, 412].includes(e.status)
          ) failed--;
        }
      }
      return { processed, failed };
    },
  };
}
