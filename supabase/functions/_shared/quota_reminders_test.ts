import { deepStrictEqual, equal, throws } from "node:assert/strict";
import {
  InvalidReminderSnapshot,
  monthlyObligations,
  prepareQuotaReminders,
  type ReminderSnapshot,
  reminderWindow,
  type ScopedDocument,
} from "./quota_reminders.ts";
import parity from "../../../test/fixtures/quota_reminder_parity.json" with {
  type: "json",
};

export const doc = (
  id: string,
  data: Record<string, unknown>,
): ScopedDocument => ({
  id,
  groupId: "qa",
  data,
});
export function snapshot(): ReminderSnapshot {
  return {
    groupId: "qa",
    group: { isActive: true, timeZone: "Europe/Madrid" },
    persons: [doc("p", { isActive: true, linkedUid: "alice" })],
    members: [doc("alice", {
      uid: "alice",
      status: "active",
      role: "owner",
      personId: "p",
    })],
    rules: [doc("24316", { effectiveFromMonth: 24316, monthlyFeeCents: 2000 })],
    periods: [doc("stage", {
      personId: "p",
      firstMonth: 24316,
      lastMonthInclusive: null,
    })],
    movements: [doc("income", {
      personId: "p",
      type: "income",
      status: "active",
      amountCents: 5000,
    })],
    allocations: [],
    preferences: [],
  };
}

Deno.test("Parity: same shared monetary fixtures as Dart monthly report", () => {
  for (const row of parity.cases) {
    const data = snapshot();
    data.rules = row.fee === null ? [] : [doc("24316", {
      effectiveFromMonth: 24316,
      monthlyFeeCents: row.fee,
    })];
    data.periods = row.periods.map(([first, last], i) =>
      doc(`stage${i}`, {
        personId: "p",
        firstMonth: first,
        lastMonthInclusive: last,
      })
    );
    data.movements[0].data.status = row.incomeStatus ?? "active";
    data.allocations = Object.entries(row.allocations).map(([month, amount]) =>
      doc(`income_${month}`, {
        movementId: "income",
        personId: "p",
        month: Number(month),
        amountCents: amount,
        revision: 1,
      })
    );
    if (row.refund) {
      const amount = row.refund.unallocatedCents +
        Object.values(row.refund.parts).reduce((a, b) => a + b, 0);
      data.movements = [
        ...data.movements,
        doc("refund", {
          type: "withdrawal",
          status: row.refundStatus ?? "active",
          personId: "p",
          amountCents: amount,
          refund: row.refund,
        }),
      ];
    }
    if (row.ordinaryWithdrawal) {
      data.movements = [
        ...data.movements,
        doc("withdrawal", {
          type: "withdrawal",
          status: "active",
          personId: "p",
          amountCents: row.ordinaryWithdrawal,
        }),
      ];
    }
    const result = monthlyObligations(data, parity.month)[0];
    deepStrictEqual(
      [
        result.expectedCents,
        Number(result.paidCents),
        result.pendingCents,
      ],
      row.expected,
      row.id,
    );
  }
});

Deno.test("Civil dates, DST, all six zones and recovery only on same day", () => {
  for (
    const [date, expected] of [
      ["2026-10-24T07:59:59Z", null], // Madrid summer time: 09:59.
      ["2026-10-24T08:00:00Z", "sevenDaysBeforeEnd"],
      ["2026-10-24T21:59:59Z", "sevenDaysBeforeEnd"],
      ["2026-10-24T22:00:00Z", null],
      ["2026-10-30T08:59:59Z", null], // Madrid standard time: 09:59.
      ["2026-10-30T09:00:00Z", "oneDayBeforeEnd"],
      ["2028-02-22T09:00:00Z", "sevenDaysBeforeEnd"],
      ["2026-02-21T09:00:00Z", "sevenDaysBeforeEnd"],
      ["2026-06-23T08:00:00Z", "sevenDaysBeforeEnd"],
      ["2026-12-30T09:00:00Z", "oneDayBeforeEnd"],
    ] as const
  ) {
    equal(
      reminderWindow(new Date(date), "Europe/Madrid")?.stage ?? null,
      expected,
    );
  }
  for (
    const [zone, utcHour] of [
      ["Atlantic/Canary", 9],
      ["Europe/London", 9],
      ["America/New_York", 14],
      ["America/Bogota", 15],
      ["America/Mexico_City", 16],
    ] as const
  ) {
    equal(
      reminderWindow(new Date(Date.UTC(2026, 9, 24, utcHour)), zone)?.stage,
      "sevenDaysBeforeEnd",
    );
  }
  throws(
    () => reminderWindow(new Date(), "Unknown/Zone"),
    InvalidReminderSnapshot,
  );
});

Deno.test("Current recipients, inactive links, manager summary and discreet drafts", () => {
  const data = snapshot();
  data.persons = [
    ...data.persons,
    doc("no-user", { isActive: true }),
    doc("former-user", { isActive: true, linkedUid: "bob" }),
    doc("inactive", { isActive: false }),
    doc("manager", { isActive: true, linkedUid: "carol" }),
  ];
  data.members = [
    ...data.members,
    doc("bob", {
      uid: "bob",
      status: "inactive",
      role: "member",
      personId: "former-user",
    }),
    doc("carol", {
      uid: "carol",
      status: "active",
      role: "admin",
      personId: "manager",
    }),
    doc("fake-admin", { uid: "fake-admin", status: "active", role: "admin" }),
  ];
  data.periods = [
    ...data.periods,
    ...["no-user", "former-user", "inactive"].map((p) =>
      doc(`stage-${p}`, {
        personId: p,
        firstMonth: 24316,
        lastMonthInclusive: null,
      })
    ),
  ];
  data.preferences = [doc("alice", { quotaPushEnabled: false })];
  const now = new Date("2026-10-24T08:00:00Z");
  const plan = prepareQuotaReminders(data, now)!;
  equal(plan.candidates.length, 3);
  equal(plan.notifications.length, 3); // Alice personal + Alice/Carol one summary each.
  equal(
    plan.notifications.filter((n) => n.kind === "unlinkedQuotaSummary").length,
    2,
  );
  equal(plan.notifications.some((n) => n.recipientUid === "bob"), false);
  equal(plan.notifications.some((n) => n.recipientUid === "fake-admin"), false);
  equal(
    plan.notifications.filter((n) => n.recipientUid === "alice")
      .every((n) => n.quotaPushEnabled === false),
    true,
  );
  equal(
    plan.notifications.every((n) => !/[0-9€$£]/.test(n.title + n.body)),
    true,
  );
  deepStrictEqual(plan.unconfiguredPersonIds, ["manager"]);
  const later = prepareQuotaReminders(data, new Date("2026-10-24T19:00:00Z"))!;
  deepStrictEqual(
    later.notifications.map((n) => n.sourceKey),
    plan.notifications.map((n) => n.sourceKey),
  );
  data.group.isActive = false;
  equal(prepareQuotaReminders(data, now), null);
});

Deno.test("Reject foreign scopes, inconsistent history/links and unsafe amounts", () => {
  const mutations: ((data: ReminderSnapshot) => void)[] = [
    (s) => {
      s.movements[0].groupId = "foreign";
    },
    (s) => {
      s.movements[0].data.amountCents = 1.1;
    },
    (s) => {
      s.movements[0].data.amountCents = Number.MAX_SAFE_INTEGER + 1;
    },
    (s) => {
      s.persons[0].data.linkedUid = "stranger";
    },
    (s) => {
      s.members[0].data.personId = "missing";
    },
    (s) => {
      s.periods = [
        ...s.periods,
        doc("overlap", {
          personId: "p",
          firstMonth: 24317,
          lastMonthInclusive: null,
        }),
      ];
    },
    (s) => {
      s.allocations = [doc("income_24317", {
        movementId: "income",
        personId: "p",
        month: 24317,
        amountCents: 5001,
        revision: 1,
      })];
    },
    (s) => {
      s.movements = [
        ...s.movements,
        doc("bad-refund", {
          type: "withdrawal",
          status: "active",
          personId: "p",
          amountCents: 500,
          refund: {
            incomeId: "income",
            unallocatedCents: 0,
            parts: { "24317": 500 },
          },
        }),
      ];
    },
  ];
  for (const mutate of mutations) {
    const data = snapshot();
    mutate(data);
    throws(
      () => prepareQuotaReminders(data, new Date("2026-10-24T08:00:00Z")),
      InvalidReminderSnapshot,
    );
  }
});
