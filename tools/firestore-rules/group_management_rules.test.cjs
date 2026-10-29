const {before, after, test} = require('node:test');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, getDocs, collection, writeBatch, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp} = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-boteparroquial-group-management', firestore: {
    rules: readFileSync(join(__dirname, '../../firestore.rules'), 'utf8')}});
});
after(async () => { if (env) await env.cleanup(); });
const identity = (name, description = '') => ({name, description});
function creation(db, id, {person = true, actor = 'owner', patch = {}, memberPatch = {}, omitMember = false, omitPerson = false, omitAudit = false} = {}) {
  const now = serverTimestamp(), batch = writeBatch(db);
  batch.set(doc(db, `groups/${id}`), {name: id, description: '', currency: 'EUR', timeZone: 'Europe/Madrid',
    isActive: true, createdBy: actor, updatedBy: actor, createdAt: now, updatedAt: now, lastAuditEventId: 'created', ...patch});
  if (!omitMember) batch.set(doc(db, `groups/${id}/members/${actor}`), {uid: actor, displayName: 'Propietario',
    role: 'owner', status: 'active', joinedAt: now, updatedAt: now, personId: person ? 'owner' : null, ...memberPatch});
  if (person && !omitPerson) batch.set(doc(db, `groups/${id}/persons/owner`), {displayName: 'Propietario', notes: null, linkedUid: actor,
    isActive: true, createdBy: actor, updatedBy: actor, createdAt: now, updatedAt: now});
  if (!omitAudit) batch.set(doc(db, `groups/${id}/auditEvents/created`), {action: 'group.created', actorUid: actor,
    entityId: id, createdAt: now, before: null, after: identity(id)});
  return batch;
}
function edit(db, id, uid, name, event = 'edit', {patch = {}, before = identity(id), audit = true} = {}) {
  const batch = writeBatch(db), now = serverTimestamp();
  batch.update(doc(db, `groups/${id}`), {name, description: '', updatedBy: uid, updatedAt: now, lastAuditEventId: event, ...patch});
  if (audit) batch.set(doc(db, `groups/${id}/auditEvents/${event}`), {action: 'group.updated', actorUid: uid,
    entityId: id, createdAt: now, before, after: identity(name)});
  return batch;
}
test('Crear grupo exige propietario propio, persona opcional y auditoría en la misma operación', async () => {
  const db = env.authenticatedContext('owner').firestore();
  await assertSucceeds(getDoc(doc(db, 'groups/missing-random-id')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'groups/missing-random-id')));
  await assertSucceeds(creation(db, 'with-person').commit());
  await assertSucceeds(creation(db, 'without-person', {person: false}).commit());
  const member = (await getDoc(doc(db, 'groups/with-person/members/owner'))).data();
  if (member.role !== 'owner' || member.personId !== 'owner') throw new Error('Owner inválido');
  for (const [index, options] of [{omitMember: true}, {omitPerson: true}, {omitAudit: true}, {actor: 'other'},
    {patch: {balanceCents: 999}}, {patch: {currency: 'JPY'}}, {patch: {timeZone: 'Invalid/Zone'}},
    {memberPatch: {uid: 'other'}}, {memberPatch: {role: 'admin'}}].entries()) {
    await assertFails(creation(db, `invalid-${index}`, options).commit());
  }
  await assertFails(creation(env.unauthenticatedContext().firestore(), 'anonymous').commit());
  await assertFails(creation(db, 'with-person').commit());
});
test('Edición auditada para owner/admin activo; moneda fija, sin autopromociones ni acceso ajeno', async () => {
  const db = env.authenticatedContext('owner').firestore();
  await creation(db, 'editable').commit();
  await env.withSecurityRulesDisabled(async ctx => {
    const seed = ctx.firestore(), now = Timestamp.now();
    for (const [uid, role, personId] of [['admin','admin','owner'], ['member','member',null], ['invalid-admin','admin',null]]) {
      await setDoc(doc(seed, `groups/editable/members/${uid}`), {uid, role, personId, displayName: uid,
        status: 'active', joinedAt: now, updatedAt: now});
    }
  });
  await assertSucceeds(edit(db, 'editable', 'owner', 'Nuevo nombre').commit());
  const admin = env.authenticatedContext('admin').firestore();
  await assertSucceeds(edit(admin, 'editable', 'admin', 'Segundo nombre', 'admin-edit', {before: identity('Nuevo nombre')}).commit());
  for (const uid of ['member', 'invalid-admin', 'outsider']) {
    await assertFails(edit(env.authenticatedContext(uid).firestore(), 'editable', uid, 'Intrusión', uid, {before: identity('Segundo nombre')}).commit());
  }
  await assertFails(edit(db, 'editable', 'owner', 'Nombre', 'no-audit', {before: identity('Segundo nombre'), audit: false}).commit());
  await assertFails(edit(db, 'editable', 'owner', 'Nombre', 'currency', {before: identity('Segundo nombre'), patch: {currency: 'USD'}}).commit());
  await assertFails(edit(db, 'editable', 'owner', 'Nombre', 'forged-before', {before: identity('Inventado')}).commit());
  await assertFails(updateDoc(doc(admin, 'groups/editable/members/admin'), {role: 'owner'}));
  await assertFails(deleteDoc(doc(db, 'groups/editable')));
  await assertFails(getDocs(collection(env.authenticatedContext('outsider').firestore(), 'groups')));
});
test('Auditoría inmutable, privada para gestión y compatible con grupos anteriores', async () => {
  const db = env.authenticatedContext('owner').firestore();
  await creation(db, 'audited').commit();
  await assertSucceeds(getDocs(collection(db, 'groups/audited/auditEvents')));
  await assertFails(updateDoc(doc(db, 'groups/audited/auditEvents/created'), {actorUid: 'other'}));
  await assertFails(deleteDoc(doc(db, 'groups/audited/auditEvents/created')));
  await assertFails(getDocs(collection(env.authenticatedContext('outsider').firestore(), 'groups/audited/auditEvents')));
  await env.withSecurityRulesDisabled(async ctx => {
    const seed = ctx.firestore(), now = Timestamp.now();
    await setDoc(doc(seed, 'groups/legacy'), {name: 'legacy', currency: 'EUR', timeZone: 'Europe/Madrid',
      isActive: true, createdBy: 'owner', createdAt: now, updatedAt: now});
    await setDoc(doc(seed, 'groups/legacy/members/owner'), {uid: 'owner', role: 'owner', status: 'active'});
    await setDoc(doc(seed, 'groups/audited/members/member'), {uid: 'member', role: 'member', status: 'active'});
  });
  await assertFails(getDocs(collection(env.authenticatedContext('member').firestore(), 'groups/audited/auditEvents')));
  await assertSucceeds(edit(db, 'legacy', 'owner', 'Actualizado', 'legacy-edit', {before: identity('legacy', null)}).commit());
});
