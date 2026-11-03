import {
  createServerAuth,
  ServerFirestore,
} from "../_shared/server_firestore.ts";
import { createFcmSender } from "../_shared/fcm.ts";
import { createWorkerHandler } from "../notification-worker/handler.ts";
import { createNotificationProbe } from "./probe.ts";

if (
  Deno.env.get("SUPABASE_URL") !== "https://qngrmxfjckrrfiyioyzl.supabase.co"
) {
  throw new Error("probe_requires_notifications_project");
}
const credentials = Deno.env.get("NOTIFICATION_FIREBASE_CREDENTIALS");
const secret = Deno.env.get("NOTIFICATION_WORKER_SECRET");
if (!credentials || !secret) throw new Error("missing_configuration");
const fcm = createFcmSender(credentials);
const run = createNotificationProbe({
  db: new ServerFirestore(createServerAuth(credentials)),
  send: (message) => fcm.send(message, { validateOnly: false }),
  groupId: "AuXu3Jg8oRW86NqLLEO9",
  uid: "8UXIz070Z9TTm4hrJcwi8OD8qoK2",
  times: [
    "2026-11-03T17:00:00Z",
    "2026-11-03T18:20:00Z",
    "2026-11-03T19:00:00Z",
  ],
  titles: [
    "BoteParroquial · Prueba 18:00",
    "BoteParroquial · Prueba 19:20",
    "BoteParroquial · Prueba 20:00",
  ],
});
Deno.serve(createWorkerHandler(secret, run));
