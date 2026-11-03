import { digest, type ServerFirestore } from "../_shared/server_firestore.ts";
import type { FcmMessage } from "../_shared/fcm.ts";

// Explicitly requested operator tests, independent of production preferences.
// Never install in the photos project. Not a client-selected delivery endpoint.
export function createNotificationProbe(deps: {
  db: Pick<ServerFirestore, "get" | "list" | "create" | "put">;
  send: (message: FcmMessage) => Promise<string>;
  groupId: string;
  uid: string;
  times: readonly string[];
  titles?: readonly string[];
  now?: () => Date;
}) {
  const now = deps.now ?? (() => new Date());
  const group = `groups/${deps.groupId}`;
  async function authorized() {
    return (await deps.db.get(group))?.data.isActive === true &&
      (await deps.db.get(`${group}/members/${deps.uid}`))?.data.status ===
        "active";
  }
  return async () => {
    let attempted = 0;
    for (let i = 0; i < deps.times.length; i++) {
      const due = Date.parse(deps.times[i]);
      // A brief, dated window: never catch up on another day or future year.
      if (
        !Number.isFinite(due) || now().getTime() < due ||
        now().getTime() >= due + 600000
      ) continue;
      if (!await authorized()) continue;
      const devices = (await deps.db.list(`users/${deps.uid}/pushDevices`, 50))
        .sort((a, b) =>
          Date.parse(String(b.data.updatedAt)) -
          Date.parse(String(a.data.updatedAt))
        );
      const device = devices[0];
      const token = device?.data.token;
      if (typeof token !== "string" || token.length < 16) continue;
      const tokenHash = await digest(token);
      if (device.path !== `users/${deps.uid}/pushDevices/${tokenHash}`) {
        continue;
      }
      const id = await digest(
        JSON.stringify(["explicit-push-test", deps.uid, deps.times[i]]),
      );
      const claim = `${group}/notificationDeliveries/${id}`;
      if (
        !await authorized() ||
        (await deps.db.get(device.path))?.data.token !== token
      ) continue;
      if (
        !await deps.db.create(claim, {
          notificationId: id,
          recipientUid: deps.uid,
          tokenHash,
          state: "attempting",
          createdAt: now(),
          updatedAt: now(),
          test: true,
          scheduledAt: deps.times[i],
        })
      ) continue;
      // Claim once per test, even across token rotation/concurrent invocations.
      let state = "uncertain";
      try {
        if (
          await authorized() &&
          (await deps.db.get(device.path))?.data.token === token
        ) {
          state = await deps.send({
            token,
            title: deps.titles?.[i] ??
              `BoteParroquial · Prueba ${i + 1} de ${deps.times.length}`,
            body:
              "Este es el aviso de prueba que pediste. No cambia cuotas ni movimientos.",
            data: { groupId: deps.groupId, recipientUid: deps.uid },
          });
          attempted++;
        } else state = "cancelled";
      } catch { /* Never retry an uncertain accepted delivery. */ }
      const stored = await deps.db.get(claim);
      if (stored) {
        await deps.db.put(claim, { ...stored.data, state, updatedAt: now() }, {
          updateTime: stored.updateTime,
        });
      }
    }
    return { attempted };
  };
}
