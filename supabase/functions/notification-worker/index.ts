import { createFcmSender } from "../_shared/fcm.ts";
import { createReminderReader } from "../_shared/reminder_reader.ts";
import {
  createServerAuth,
  ServerFirestore,
} from "../_shared/server_firestore.ts";
import { createWorkerHandler } from "./handler.ts";
import { createNotificationWorker } from "./worker.ts";

// Deploy ONLY to the isolated notifications Supabase project, never the photos
// project: project-level Edge secrets would otherwise cross that boundary.
if (
  Deno.env.get("SUPABASE_URL") === "https://ietnizafvtovelyuxbvk.supabase.co"
) {
  throw new Error("worker_requires_isolated_project");
}
const credentials = Deno.env.get("NOTIFICATION_FIREBASE_CREDENTIALS");
const secret = Deno.env.get("NOTIFICATION_WORKER_SECRET");
const startedAt = Deno.env.get("NOTIFICATION_STARTED_AT");
if (!credentials || !secret || !startedAt) {
  throw new Error("missing_worker_configuration");
}
const token = createServerAuth(credentials);
const reader = createReminderReader({ accessToken: token });
const fcm = createFcmSender(credentials);
const worker = createNotificationWorker({
  db: new ServerFirestore(token),
  readQuotas: (groupId) => reader.read(groupId),
  startedAt: new Date(startedAt),
  send: (message) => fcm.send(message, { validateOnly: false }),
});
Deno.serve(createWorkerHandler(secret, () => worker.run()));
