import { deepStrictEqual, equal, rejects } from "node:assert/strict";
import { createReminderReader, ReminderReadError } from "./reminder_reader.ts";
import { prepareQuotaReminders } from "./quota_reminders.ts";

const root = "projects/boteparroquial/databases/(default)/documents";
const group = `${root}/groups/qa`;
const string = (value: string) => ({ stringValue: value });
const integer = (value: number) => ({ integerValue: String(value) });
const document = (path: string, fields: Record<string, unknown>) => ({
  name: `${group}/${path}`,
  fields,
});

Deno.test("Complete read-only snapshot, pagination, current preferences and plan", async () => {
  let released = false, pages = 0;
  const reader = createReminderReader({
    accessToken: () => Promise.resolve("DEMO-OAuth"),
    fetch: async (input, init) => {
      const url = new URL(String(input));
      equal(url.origin, "https://firestore.googleapis.com");
      equal(
        new Headers(init?.headers).get("Authorization"),
        "Bearer DEMO-OAuth",
      );
      equal(init?.redirect, "error");
      if (url.pathname.endsWith(":beginTransaction")) {
        deepStrictEqual(await new Response(init?.body).json(), {
          options: { readOnly: {} },
        });
        return Response.json({ transaction: "DEMO-snapshot" });
      }
      if (url.pathname.endsWith(":rollback")) {
        equal(
          (await new Response(init?.body).json()).transaction,
          "DEMO-snapshot",
        );
        released = true;
        return Response.json({});
      }
      equal(init?.method, "GET");
      equal(url.searchParams.get("transaction"), "DEMO-snapshot");
      equal(url.searchParams.has("mask.fieldPaths"), true);
      const path = url.pathname.split("/groups/qa")[1];
      if (path === "") {
        return Response.json({
          name: group,
          fields: {
            isActive: { booleanValue: true },
            timeZone: string("Europe/Madrid"),
          },
        });
      }
      if (path === "/persons") {
        pages++;
        if (!url.searchParams.has("pageToken")) {
          return Response.json({
            documents: [document("persons/p", {
              isActive: { booleanValue: true },
              linkedUid: string("alice"),
            })],
            nextPageToken: "second-page",
          });
        }
        equal(url.searchParams.get("pageToken"), "second-page");
        return Response.json({documents:[document("persons/trashed", {
          isActive:{booleanValue:false},trashedAt:{timestampValue:"2026-06-01T00:00:00Z"},
        })]}); // Trashed people are not unconfigured quota participants.
      }
      if (path === "/members") {
        return Response.json({
          documents: [document("members/alice", {
            uid: string("alice"),
            role: string("owner"),
            status: string("active"),
            personId: string("p"),
          })],
        });
      }
      if (path === "/quotaRules") {
        return Response.json({
          documents: [document("quotaRules/24316", {
            effectiveFromMonth: integer(24316),
            monthlyFeeCents: integer(2000),
          })],
        });
      }
      if (path === "/participationPeriods") {
        return Response.json({
          documents: [document("participationPeriods/stage", {
            personId: string("p"),
            firstMonth: integer(24316),
            lastMonthInclusive: { nullValue: null },
          })],
        });
      }
      if (path === "/members/alice/notificationPreferences/reminders") {
        return Response.json(
          document("members/alice/notificationPreferences/reminders", {
            quotaPushEnabled: { booleanValue: false },
          }),
        );
      }
      if (["/movements", "/allocations"].includes(path)) {
        return Response.json({});
      }
      throw new Error("unexpected mock request");
    },
  });
  const snapshot = await reader.read("qa");
  equal(released, true);
  equal(pages, 2);
  equal(snapshot.persons.length, 1);
  const plan = prepareQuotaReminders(
    snapshot,
    new Date("2026-10-24T08:00:00Z"),
  )!;
  equal(plan.candidates[0].pendingCents, 2000);
  equal(plan.notifications[0].recipientUid, "alice");
  equal(plan.notifications[0].quotaPushEnabled, false);
});

Deno.test("Incomplete, foreign, unsafe or excessive reads fail without partial plan", async () => {
  for (
    const mode of [
      "foreign",
      "float",
      "unsafe",
      "overflow",
      "network",
      "oauth",
    ] as const
  ) {
    let released = false;
    const reader = createReminderReader({
      accessToken: () =>
        mode === "oauth"
          ? Promise.reject(new Error("DEMO private technical detail"))
          : Promise.resolve("DEMO"),
      maxDocuments: mode === "overflow" ? 1 : 10,
      fetch: (input) => {
        const url = new URL(String(input));
        if (url.pathname.endsWith(":beginTransaction")) {
          return Promise.resolve(Response.json({ transaction: "tx" }));
        }
        if (url.pathname.endsWith(":rollback")) {
          released = true;
          return Promise.resolve(Response.json({}));
        }
        if (url.pathname.endsWith("groups/qa")) {
          return Promise.resolve(Response.json({
            name: group,
            fields: {
              isActive: { booleanValue: true },
              timeZone: string("Europe/Madrid"),
            },
          }));
        }
        if (mode === "network") {
          return Promise.reject(new Error("DEMO private technical detail"));
        }
        const bad = mode === "foreign"
          ? { name: `${root}/groups/other/persons/p`, fields: {} }
          : document("persons/p", {
            isActive: mode === "float"
              ? { doubleValue: 1.1 }
              : mode === "unsafe"
              ? { integerValue: "9007199254740993" }
              : { booleanValue: true },
          });
        return Promise.resolve(Response.json({ documents: [bad] }));
      },
    });
    await rejects(() => reader.read("qa"), (error) => {
      equal(error instanceof ReminderReadError, true);
      equal(String(error).includes("private technical detail"), false);
      return true;
    });
    equal(released, mode !== "oauth", mode);
  }
});
