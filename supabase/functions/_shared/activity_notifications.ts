import type { ServerDocument } from "./server_firestore.ts";

export type ActivityKind =
  | "joinRequested"
  | "memberAccepted"
  | "memberJoined"
  | "unlinkedMember"
  | "linkChanged"
  | "adminGranted"
  | "adminLost"
  | "incomeAssociated"
  | "withdrawalAssociated"
  | "quotaChanged"
  | "ownershipTransferred"
  | "movementCancelled"
  | "invitationRegenerated";
export type Notice = {
  sourceKey: string;
  recipientUid: string;
  kind: string;
  category: "reminders" | "economic" | "informative";
  title: string;
  body: string;
  audience: "member" | "manager";
};
export class GroupAudience {
  readonly members = new Map<string, Record<string, unknown>>();
  readonly persons = new Map<string, Record<string, unknown>>();
  constructor(
    readonly groupId: string,
    members: ServerDocument[],
    persons: ServerDocument[],
  ) {
    for (const doc of members) {
      const uid = doc.path.split("/").at(-1)!;
      if (
        doc.path !== `groups/${groupId}/members/${uid}` || doc.data.uid !== uid
      ) throw new Error("invalid_audience");
      this.members.set(uid, doc.data);
    }
    for (const doc of persons) {
      const id = doc.path.split("/").at(-1)!;
      if (doc.path !== `groups/${groupId}/persons/${id}`) {
        throw new Error("invalid_audience");
      }
      this.persons.set(id, doc.data);
    }
  }
  active(uid: string) {
    const member = this.members.get(uid);
    return member?.status === "active" &&
      ["owner", "admin", "member"].includes(String(member.role));
  }
  manager(uid: string) {
    const member = this.members.get(uid);
    const person = this.persons.get(String(member?.personId));
    return this.active(uid) && (member?.role === "owner" ||
      (member?.role === "admin" && person?.isActive === true &&
        person.linkedUid === uid));
  }
  linked(personId: unknown): string | null {
    const uid = this.persons.get(String(personId))?.linkedUid;
    return typeof uid === "string" && this.active(uid) &&
        this.members.get(uid)?.personId === personId
      ? uid
      : null;
  }
  managers() {
    return [...this.members.keys()].filter((uid) => this.manager(uid));
  }
}
const texts: Record<ActivityKind, string> = {
  joinRequested: "Hay una solicitud de acceso pendiente de revisar.",
  memberAccepted: "Tu acceso al grupo ha sido aprobado.",
  memberJoined: "Una persona ha entrado en el grupo.",
  unlinkedMember: "Hay una cuenta del grupo sin persona vinculada.",
  linkChanged: "Ha cambiado tu vinculación con una persona del grupo.",
  adminGranted: "Ahora tienes permisos de administración en el grupo.",
  adminLost: "Han cambiado tus permisos de administración en el grupo.",
  incomeAssociated: "Se ha registrado un ingreso asociado a tu persona.",
  withdrawalAssociated: "Se ha registrado una retirada asociada a tu persona.",
  quotaChanged: "Ha cambiado la configuración de cuotas del grupo.",
  ownershipTransferred: "Ha cambiado la propiedad del grupo.",
  movementCancelled: "Se ha anulado un movimiento asociado a tu persona.",
  invitationRegenerated: "Se ha regenerado el código de invitación del grupo.",
};
export function activityNotices(
  source: ServerDocument,
  audience: GroupAudience,
): Notice[] {
  const prefix = `groups/${audience.groupId}/`;
  if (!source.path.startsWith(prefix)) throw new Error("foreign_activity");
  const data = source.data;
  const before = (data.before ?? {}) as Record<string, unknown>;
  const after = (data.after ?? {}) as Record<string, unknown>;
  const result = new Map<string, Notice>();
  function add(
    kind: ActivityKind,
    uids: string[],
    manager = false,
    self = false,
    actor = data.actorUid,
  ) {
    const category = [
        "incomeAssociated",
        "withdrawalAssociated",
        "movementCancelled",
        "quotaChanged",
      ].includes(kind)
      ? "economic"
      : "informative";
    for (const uid of uids) {
      if (
        !audience.active(uid) || (manager && !audience.manager(uid)) ||
        (!self && uid === actor)
      ) continue;
      const sourceKey = JSON.stringify([
        "activity-v1",
        source.path,
        source.path.includes("/movements/") ? data.status : "audit",
        kind,
        uid,
      ]);
      result.set(sourceKey, {
        sourceKey,
        recipientUid: uid,
        kind,
        category,
        title: "BoteParroquial",
        body: texts[kind],
        audience: manager ? "manager" : "member",
      });
    }
  }
  const target = typeof data.entityId === "string" ? [data.entityId] : [];
  if (source.path.startsWith(`${prefix}movements/`)) {
    const uid = audience.linked(data.personId);
    if (uid && data.status === "active") {
      add(
        data.type === "income" ? "incomeAssociated" : "withdrawalAssociated",
        [uid],
        false,
        false,
        data.createdBy,
      );
    }
    if (uid && data.status === "cancelled") {
      add("movementCancelled", [uid], false, false, data.cancelledBy);
    }
  } else if (source.path.startsWith(`${prefix}auditEvents/`)) {
    switch (data.action) {
      case "join.requested":
        add("joinRequested", audience.managers(), true);
        break;
      case "join.approved":
      case "join.accepted": {
        if (!target.some((uid) => audience.active(uid))) break;
        if (data.action === "join.approved") {
          add("memberAccepted", target, false, true);
        }
        add("memberJoined", audience.managers(), true);
        if (target.some((uid) => !audience.members.get(uid)?.personId)) {
          add("unlinkedMember", audience.managers(), true);
        }
        break;
      }
      case "member.linkChanged":
        if (
          !target.some((uid) =>
            (audience.members.get(uid)?.personId ?? null) ===
              (after.personId ?? null)
          )
        ) break;
        add("linkChanged", target, false, true);
        if (after.personId == null) {
          add("unlinkedMember", audience.managers(), true);
        }
        if (before.role === "admin" && after.role === "member") {
          add("adminLost", target, false, true);
        }
        break;
      case "member.roleChanged":
        if (
          !target.some((uid) => audience.members.get(uid)?.role === after.role)
        ) break;
        add(
          after.role === "admin" ? "adminGranted" : "adminLost",
          target,
          false,
          true,
        );
        break;
      case "person.inactivated":
        if (
          before.role === "admin" && after.role === "member" &&
          typeof after.linkedUid === "string"
        ) add("adminLost", [after.linkedUid], false, true);
        break;
      case "quota.changed":
        add("quotaChanged", [...audience.members.keys()]);
        break;
      case "group.ownershipTransferred":
        add("ownershipTransferred", audience.managers(), true);
        add(
          "ownershipTransferred",
          [before.ownerUid, after.ownerUid].filter((u): u is string =>
            typeof u === "string"
          ),
          false,
          true,
        );
        break;
      case "invitation.changed":
        if (data.before != null && after.regenerated === true) {
          add("invitationRegenerated", audience.managers(), true);
        }
        break;
    }
  }
  return [...result.values()];
}
