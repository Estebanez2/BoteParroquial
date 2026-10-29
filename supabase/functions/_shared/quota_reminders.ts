/** Server-side domain only. Input must be a complete, consistent server read,
 * never a Flutter request body. No SDK, credentials, I/O or delivery side effects.
 */
export type ScopedDocument = {
  id: string;
  groupId: string;
  data: Record<string, unknown>;
};
export type ReminderSnapshot = {
  groupId: string;
  group: { isActive: boolean; timeZone: string };
  persons: readonly ScopedDocument[];
  members: readonly ScopedDocument[];
  rules: readonly ScopedDocument[];
  periods: readonly ScopedDocument[];
  movements: readonly ScopedDocument[];
  allocations: readonly ScopedDocument[];
  /** Only reminders preferences, keyed by member UID; absent means enabled. */
  preferences: readonly ScopedDocument[];
};
export type ReminderStage = "sevenDaysBeforeEnd" | "oneDayBeforeEnd";
export type Obligation = {
  personId: string;
  expectedCents: number | null;
  paidCents: bigint;
  pendingCents: number | null;
};
export type NotificationDraft = {
  recipientUid: string;
  kind: "quotaReminder" | "unlinkedQuotaSummary";
  title: string;
  body: string;
  quotaPushEnabled: boolean;
  /** Logical idempotency tuple, not a database ID or a delivery guarantee. */
  sourceKey: string;
};
export class InvalidReminderSnapshot extends Error {
  constructor() {
    super("invalid_reminder_snapshot");
  }
}
function invalid(): never {
  throw new InvalidReminderSnapshot();
}
const maxCents = 99999999999999;
const zones = new Set([
  "Europe/Madrid",
  "Atlantic/Canary",
  "Europe/London",
  "America/New_York",
  "America/Bogota",
  "America/Mexico_City",
]);
function id(value: unknown): string {
  if (typeof value !== "string" || !value || value.includes("/")) invalid();
  return value as string;
}
function month(value: unknown): number {
  if (
    !Number.isInteger(value) || (value as number) < 24000 ||
    (value as number) > 25211
  ) invalid();
  return value as number;
}
function cents(value: unknown, positive = false): bigint {
  if (
    !Number.isSafeInteger(value) || (value as number) < (positive ? 1 : 0) ||
    (value as number) > maxCents
  ) invalid();
  return BigInt(value as number);
}
function bool(value: unknown): boolean {
  if (typeof value !== "boolean") invalid();
  return value as boolean;
}
function optionalId(value: unknown): string | null {
  return value == null ? null : id(value);
}
function index(docs: readonly ScopedDocument[], groupId: string) {
  if (!Array.isArray(docs)) invalid();
  const result = new Map<string, Record<string, unknown>>();
  for (const doc of docs) {
    if (
      !doc || doc.groupId !== groupId || !doc.data ||
      typeof doc.data !== "object" || Array.isArray(doc.data) ||
      result.has(id(doc.id))
    ) invalid();
    result.set(doc.id, doc.data);
  }
  return result;
}

/** Current-month projection with the same semantics as Dart's expectation,
 * settlement and monthly report repositories. BigInt keeps aggregate cents exact.
 */
export function monthlyObligations(
  snapshot: ReminderSnapshot,
  currentMonth: number,
): Obligation[] {
  const groupId = id(snapshot.groupId);
  month(currentMonth);
  const people = index(snapshot.persons, groupId);
  const rules = [...index(snapshot.rules, groupId)].map(([key, data]) => {
    const start = month(data.effectiveFromMonth);
    if (key !== String(start)) invalid();
    return { start, amount: cents(data.monthlyFeeCents) };
  }).sort((a, b) => a.start - b.start);
  const periods = [...index(snapshot.periods, groupId)].map(([, data]) => {
    const personId = id(data.personId);
    const start = month(data.firstMonth);
    const end = data.lastMonthInclusive == null
      ? null
      : month(data.lastMonthInclusive);
    if (!people.has(personId) || (end !== null && end < start)) invalid();
    return { personId, start, end };
  });
  const money = index(snapshot.movements, groupId);
  const amounts = new Map<string, bigint>();
  for (const [key, data] of money) {
    if (
      !["income", "withdrawal"].includes(String(data.type)) ||
      !["active", "cancelled", "corrected"].includes(String(data.status))
    ) {
      invalid();
    }
    const personId = optionalId(data.personId);
    if (personId !== null && !people.has(personId)) invalid();
    amounts.set(key, cents(data.amountCents, true));
  }
  const assigned = new Map<string, bigint>();
  const allocatedByIncome = new Map<string, bigint>();
  const allocations = index(snapshot.allocations, groupId);
  for (const [key, data] of allocations) {
    const incomeId = id(data.movementId);
    const source = money.get(incomeId);
    const ordinal = month(data.month);
    const amount = cents(data.amountCents);
    if (
      key !== `${incomeId}_${ordinal}` || !source || source.type !== "income" ||
      !people.has(id(data.personId)) || source.personId !== data.personId ||
      !Number.isInteger(data.revision) || (data.revision as number) < 1
    ) invalid();
    assigned.set(key, amount);
    const sum = (allocatedByIncome.get(incomeId) ?? 0n) + amount;
    if (sum > amounts.get(incomeId)!) invalid();
    allocatedByIncome.set(incomeId, sum);
  }
  const returned = new Map<string, bigint>();
  const returnedByIncome = new Map<string, bigint>();
  const returnedAssigned = new Map<string, bigint>();
  for (const [key, data] of money) {
    if (data.refund == null) continue;
    const refund = data.refund;
    if (typeof refund !== "object" || Array.isArray(refund)) invalid();
    const plan = refund as Record<string, unknown>;
    const incomeId = id(plan.incomeId);
    const source = money.get(incomeId);
    if (
      data.type !== "withdrawal" || data.personId == null || !source ||
      source.type !== "income" || source.personId !== data.personId ||
      !plan.parts || typeof plan.parts !== "object" || Array.isArray(plan.parts)
    ) {
      invalid();
    }
    const parts = Object.entries(plan.parts as Record<string, unknown>);
    if (parts.length > 4) invalid();
    let total = cents(plan.unallocatedCents), totalAssigned = 0n;
    for (const [rawMonth, value] of parts) {
      const ordinal = month(Number(rawMonth));
      if (String(ordinal) !== rawMonth) invalid();
      const amount = cents(value, true);
      total += amount;
      totalAssigned += amount;
      if (data.status === "active") {
        const allocationId = `${incomeId}_${ordinal}`;
        returned.set(allocationId, (returned.get(allocationId) ?? 0n) + amount);
      }
    }
    if (total !== amounts.get(key)) invalid();
    if (data.status !== "active") continue;
    if (source.status !== "active") invalid();
    returnedByIncome.set(
      incomeId,
      (returnedByIncome.get(incomeId) ?? 0n) + total,
    );
    returnedAssigned.set(
      incomeId,
      (returnedAssigned.get(incomeId) ?? 0n) + totalAssigned,
    );
  }
  for (const [key, amount] of returned) {
    if (!assigned.has(key) || amount > assigned.get(key)!) invalid();
  }
  for (const [key, amount] of amounts) {
    if (money.get(key)!.type !== "income") continue;
    const free = amount - (allocatedByIncome.get(key) ?? 0n) -
      (returnedByIncome.get(key) ?? 0n) + (returnedAssigned.get(key) ?? 0n);
    if (free < 0n || (returnedByIncome.get(key) ?? 0n) > amount) invalid();
  }
  const currentRule = rules.filter((r) => r.start <= currentMonth).at(-1);
  const result: Obligation[] = [];
  for (const [personId, person] of people) {
    const active = bool(person.isActive);
    const stages = periods.filter((p) => p.personId === personId).sort((a, b) =>
      a.start - b.start || (a.end ?? Infinity) - (b.end ?? Infinity)
    );
    for (let i = 1; i < stages.length; i++) {
      const previous = stages[i - 1].end;
      // Sharing only a boundary month is allowed; count it once below.
      if (previous === null || stages[i].start < previous) invalid();
    }
    let paid = 0n;
    for (const [key, allocation] of allocations) {
      if (
        allocation.personId === personId && allocation.month === currentMonth &&
        money.get(allocation.movementId as string)!.status === "active"
      ) {
        paid += assigned.get(key)! - (returned.get(key) ?? 0n);
      }
    }
    const applies = stages.some((p) =>
      p.start <= currentMonth && (p.end === null || p.end >= currentMonth)
    );
    const expected = stages.length === 0
      ? null
      : !applies
      ? 0n
      : currentRule?.amount ?? null;
    if (!active) continue;
    result.push({
      personId,
      expectedCents: expected === null ? null : Number(expected),
      paidCents: paid,
      pendingCents: expected === null
        ? null
        : Number(expected > paid ? expected - paid : 0n),
    });
  }
  return result.sort((a, b) => a.personId.localeCompare(b.personId));
}

/** Calendar is from server time and the group's supported IANA zone. D096:
 * recover after 10:00 only during that same local reminder day, never tomorrow.
 */
export function reminderWindow(now: Date, timeZone: string): {
  month: number;
  stage: ReminderStage;
} | null {
  if (!zones.has(timeZone) || !Number.isFinite(now.getTime())) invalid();
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    hourCycle: "h23",
  }).formatToParts(now);
  const get = (type: string) =>
    Number(parts.find((p) => p.type === type)?.value);
  const year = get("year"), m = get("month"), day = get("day");
  const ordinal = month(year * 12 + m - 1);
  const lastDay = new Date(Date.UTC(year, m, 0)).getUTCDate();
  if (get("hour") < 10) return null;
  const stage = day === lastDay - 7
    ? "sevenDaysBeforeEnd"
    : day === lastDay - 1
    ? "oneDayBeforeEnd"
    : null;
  return stage === null ? null : { month: ordinal, stage };
}

export function prepareQuotaReminders(snapshot: ReminderSnapshot, now: Date) {
  id(snapshot.groupId);
  if (!bool(snapshot.group.isActive)) return null;
  const window = reminderWindow(now, snapshot.group.timeZone);
  if (window === null) return null;
  const { month: currentMonth, stage } = window;
  const obligations = monthlyObligations(snapshot, window.month);
  const people = index(snapshot.persons, snapshot.groupId);
  const members = index(snapshot.members, snapshot.groupId);
  const preferences = index(snapshot.preferences, snapshot.groupId);
  const linkedUsers = new Set<string>();
  for (const [personId, person] of people) {
    const uid = optionalId(person.linkedUid);
    if (uid === null) continue;
    if (linkedUsers.has(uid) || members.get(uid)?.personId !== personId) {
      invalid();
    }
    linkedUsers.add(uid);
  }
  const managers: string[] = [];
  for (const [uid, member] of members) {
    if (
      member.uid !== uid ||
      !["active", "inactive"].includes(String(member.status)) ||
      !["owner", "admin", "member"].includes(String(member.role))
    ) invalid();
    const personId = optionalId(member.personId);
    const person = personId === null ? undefined : people.get(personId);
    if (personId !== null && (!person || person.linkedUid !== uid)) invalid();
    if (member.status !== "active") continue;
    if (
      member.role === "owner" ||
      (member.role === "admin" && person?.isActive === true)
    ) managers.push(uid);
  }
  for (const [uid, preference] of preferences) {
    if (!members.has(uid)) invalid();
    bool(preference.quotaPushEnabled);
  }
  const notifications: NotificationDraft[] = [];
  const candidates = obligations.filter((o) => (o.pendingCents ?? 0) > 0);
  const unconfiguredPersonIds = obligations.filter((o) =>
    o.pendingCents === null
  )
    .map((o) => o.personId);
  function add(uid: string, kind: NotificationDraft["kind"]) {
    notifications.push({
      recipientUid: uid,
      kind,
      title: "BoteParroquial",
      body: kind === "quotaReminder"
        ? "Tienes una aportación pendiente. Abre el grupo para revisarla."
        : "Hay aportaciones pendientes de revisar en tu grupo. Abre la app.",
      quotaPushEnabled: preferences.get(uid)?.quotaPushEnabled !== false,
      sourceKey: JSON.stringify([
        "quota-v1",
        snapshot.groupId,
        currentMonth,
        stage,
        kind,
        uid,
      ]),
    });
  }
  let needsManagerSummary = false;
  for (const candidate of candidates) {
    const uid = optionalId(people.get(candidate.personId)!.linkedUid);
    if (uid !== null && members.get(uid)?.status === "active") {
      add(uid, "quotaReminder");
    } else {
      // D096: a preserved link to a former member is not an eligible recipient.
      needsManagerSummary = true;
    }
  }
  if (needsManagerSummary) {
    for (const uid of managers.sort()) add(uid, "unlinkedQuotaSummary");
  }
  notifications.sort((a, b) => a.sourceKey.localeCompare(b.sourceKey));
  return { ...window, candidates, unconfiguredPersonIds, notifications };
}
