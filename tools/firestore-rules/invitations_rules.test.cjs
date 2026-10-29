const {before, beforeEach, after, test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, getDocs, collection, writeBatch, setDoc, updateDoc, deleteDoc, runTransaction, serverTimestamp, Timestamp} = require('firebase/firestore');
let env, sequence = 0;
const code = 'a'.repeat(32), secondCode = 'b'.repeat(32);
const path = (suffix) => `groups/a/${suffix}`;
const requestSummary = d => d == null ? null : ({uid:d.uid, displayName:d.displayName, status:d.status});
const memberSummary = d => ({uid:d.uid, role:d.role, status:d.status, personId:d.personId ?? null});
const settingsSummary = d => d == null ? null : ({enabled:d.enabled, requiresApproval:d.requiresApproval});
const dbFor = uid => env.authenticatedContext(uid).firestore();
before(async () => {
  env = await initializeTestEnvironment({projectId:'demo-boteparroquial-invitations', firestore:{
    rules:readFileSync(join(__dirname, '../../firestore.rules'), 'utf8')}});
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore(), batch = writeBatch(db), now = Timestamp.now();
    batch.set(doc(db,'groups/a'), {name:'Prueba', description:'', currency:'EUR', timeZone:'Europe/Madrid',
      isActive:true, createdBy:'owner', createdAt:now, updatedAt:now});
    batch.set(doc(db,'groups/b'), {name:'Ajeno', isActive:true});
    batch.set(doc(db,path('persons/p')), {displayName:'Persona histórica', isActive:true});
    batch.set(doc(db,path('movements/historical')), {amountCents:2050, status:'active', personId:'p'});
    for (const [uid,role,status,personId] of [
      ['owner','owner','active',null], ['admin','admin','active','p'],
      ['member','member','active',null], ['invalid-admin','admin','active',null],
      ['former','member','inactive','p'],
    ]) batch.set(doc(db,path(`members/${uid}`)), {uid, displayName:uid, role, status, personId, joinedAt:now, updatedAt:now});
    await batch.commit();
  });
});
async function configure(db, actor, {secret=code, enabled=true, approval=true, audit=true}={}) {
  const ref=doc(db,path('invitationSettings/current')), before=(await getDoc(ref)).data();
  const preview=doc(db,path(`invitations/${secret}`)), existing=(await getDoc(preview)).data();
  const id=`settings-${++sequence}`, batch=writeBatch(db), now=serverTimestamp();
  batch.set(ref, {code:secret, enabled, requiresApproval:approval, updatedBy:actor, updatedAt:now, lastAuditEventId:id});
  batch.set(preview, {groupName:'Prueba', currency:'EUR', requiresApproval:approval, createdAt:existing?.createdAt ?? now, updatedAt:now});
  if (audit) batch.set(doc(db,path(`auditEvents/${id}`)), {action:'invitation.changed', entityType:'invitation', entityId:'current',
    actorUid:actor, createdAt:now, before:settingsSummary(before), after:{enabled, requiresApproval:approval, regenerated:before?.code !== secret}});
  return batch.commit();
}
async function submit(db, uid, {secret=code, status='pending', role='member', audit=true, member=true}={}) {
  return runTransaction(db,async tx => {
    const ref=doc(db,path(`joinRequests/${uid}`)), before=(await tx.get(ref)).data();
    // Same reads as the Flutter service: self records may be missing and config stays private.
    await tx.get(doc(db,path(`members/${uid}`)));
    await tx.get(doc(db,path(`invitations/${secret}`)));
    const now=serverTimestamp(), id=`join-${++sequence}`;
    const data={uid, displayName:uid, code:secret, status, createdAt:before?.createdAt ?? now, updatedAt:now,
      reviewedBy:status==='approved'?uid:null, reviewedAt:status==='approved'?now:null, lastAuditEventId:id};
    tx.set(ref,data);
    if(status==='approved' && member) tx.set(doc(db,path(`members/${uid}`)), {uid, displayName:uid, role, status:'active',
      personId:null, joinedAt:now, updatedAt:now, lastAuditEventId:id});
    if(audit) tx.set(doc(db,path(`auditEvents/${id}`)), {action:status==='approved'?'join.accepted':'join.requested',
      entityType:'joinRequest', entityId:uid, actorUid:uid, createdAt:now, before:requestSummary(before), after:requestSummary(data)});
  });
}
async function decide(db, actor, uid, approve, {role='member', omitMember=false, memberPatch={}}={}) {
  const ref=doc(db,path(`joinRequests/${uid}`)), before=(await getDoc(ref)).data();
  const target=doc(db,path(`members/${uid}`)), old=(await getDoc(target)).data(), now=serverTimestamp(), id=`decision-${++sequence}`;
  const data={...before,status:approve?'approved':'rejected',reviewedBy:actor,reviewedAt:now,updatedAt:now,lastAuditEventId:id};
  const batch=writeBatch(db);
  batch.set(ref,data);
  if(approve && !omitMember) batch.set(target,{uid,displayName:before.displayName,role,status:'active',
    personId:old?.personId ?? null, joinedAt:old?.joinedAt ?? now, updatedAt:now,lastAuditEventId:id,...memberPatch});
  batch.set(doc(db,path(`auditEvents/${id}`)), {action:approve?'join.approved':'join.rejected',entityType:'joinRequest',entityId:uid,
    actorUid:actor,createdAt:now,before:requestSummary(before),after:requestSummary(data)});
  return batch.commit();
}
async function remove(db, actor, uid, {audit=true, patch={}}={}) {
  const ref=doc(db,path(`members/${uid}`)), before=(await getDoc(ref)).data(), now=serverTimestamp(), id=`remove-${++sequence}`;
  const data={...before,role:'member',status:'inactive',updatedAt:now,lastAuditEventId:id,...patch}, batch=writeBatch(db);
  batch.set(ref,data);
  if(audit) batch.set(doc(db,path(`auditEvents/${id}`)), {action:actor===uid?'member.left':'member.removed',entityType:'member',entityId:uid,
    actorUid:actor,createdAt:now,before:memberSummary(before),after:memberSummary(data)});
  return batch.commit();
}

test('Código privado: configuración auditada, vista previa limitada, regeneración y desactivación', async () => {
  const owner=dbFor('owner'), outsider=dbFor('outside');
  await assertFails(configure(owner,'owner',{audit:false}));
  await assertSucceeds(configure(owner,'owner'));
  const preview=doc(outsider,path(`invitations/${code}`));
  await assertSucceeds(getDoc(preview));
  await assertFails(getDocs(collection(outsider,path('invitations'))));
  await assertFails(getDoc(doc(outsider,path('invitationSettings/current'))));
  await assertFails(getDoc(doc(outsider,'groups/a')));
  await assertFails(getDocs(collection(outsider,path('members'))));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),path(`invitations/${code}`))));
  await assertFails(configure(dbFor('member'),'member'));
  await assertFails(configure(dbFor('invalid-admin'),'invalid-admin'));
  await assertSucceeds(configure(dbFor('admin'),'admin',{secret:secondCode}));
  await assertFails(getDoc(preview));
  await assertFails(submit(outsider,'outside',{secret:code}));
  await assertSucceeds(getDoc(doc(outsider,path(`invitations/${secondCode}`))));
  await assertSucceeds(configure(owner,'owner',{secret:secondCode,enabled:false}));
  await assertFails(getDoc(doc(outsider,path(`invitations/${secondCode}`))));
  await assertFails(submit(outsider,'outside',{secret:secondCode}));
  // Renaming with an existing invitation keeps the limited preview in sync.
  const rename=writeBatch(owner), now=serverTimestamp();
  rename.update(doc(owner,'groups/a'),{name:'Renombrado',updatedBy:'owner',updatedAt:now,lastAuditEventId:'rename'});
  rename.update(doc(owner,path(`invitations/${secondCode}`)),{groupName:'Renombrado',updatedAt:now});
  rename.set(doc(owner,path('auditEvents/rename')),{action:'group.updated',entityId:'a',actorUid:'owner',createdAt:now,
    before:{name:'Prueba',description:''},after:{name:'Renombrado',description:''}});
  await assertSucceeds(rename.commit());
});

test('Entrada automática atómica, sin elevación de rol ni acceso cruzado', async () => {
  const owner=dbFor('owner');
  await configure(owner,'owner',{approval:false});
  for(const options of [{role:'admin'}, {role:'owner'}, {audit:false}, {member:false}]) {
    await assertFails(submit(dbFor('new'),'new',{status:'approved',...options}));
  }
  await assertSucceeds(submit(dbFor('new'),'new',{status:'approved'}));
  assert.equal((await getDoc(doc(owner,path('members/new')))).data().role,'member');
  await assertSucceeds(getDoc(doc(dbFor('new'),'groups/a')));
  await assertFails(getDoc(doc(dbFor('new'),'groups/b')));
  await assertFails(getDocs(collection(dbFor('new'),path('joinRequests'))));
  await assertFails(updateDoc(doc(dbFor('new'),path('members/new')),{role:'admin'}));
  // An old membership must never regain access through automatic entry.
  await assertFails(submit(dbFor('former'),'former',{status:'approved'}));
  await assertSucceeds(submit(dbFor('former'),'former',{status:'pending'}));
});

test('Readmisión siempre aprobada por gestión: salida y expulsión sin restaurar privilegios ni alterar historia', async () => {
  const owner=dbFor('owner'), admin=dbFor('admin'), former=dbFor('former');
  await configure(owner,'owner',{approval:false});
  const previous=(await getDoc(doc(owner,path('members/former')))).data();
  await assertFails(submit(former,'former',{status:'approved'}));
  await assertSucceeds(submit(former,'former'));
  await assertFails(getDoc(doc(former,'groups/a')));
  await assertFails(decide(former,'former','former',true));
  await assertFails(decide(owner,'owner','former',true,{omitMember:true}));
  await assertFails(decide(owner,'owner','former',true,{role:'admin'}));
  await assertFails(decide(owner,'owner','former',true,{memberPatch:{personId:null}}));
  await assertFails(decide(owner,'owner','former',true,{memberPatch:{joinedAt:serverTimestamp()}}));
  await assertSucceeds(decide(admin,'admin','former',true));
  const current=(await getDoc(doc(owner,path('members/former')))).data();
  assert.equal(current.role,'member'); assert.equal(current.status,'active');
  assert.equal(current.personId,'p'); assert(current.joinedAt.isEqual(previous.joinedAt));
  await assertSucceeds(getDoc(doc(former,'groups/a')));
  await assertSucceeds(remove(former,'former','former'));
  await assertFails(submit(former,'former',{status:'approved'}));
  await assertSucceeds(submit(former,'former'));
  await assertSucceeds(decide(owner,'owner','former',false));
  await assertFails(getDoc(doc(former,'groups/a')));
  // An expelled administrator may request re-entry, but returns only as member.
  await assertSucceeds(remove(owner,'owner','admin'));
  await assertSucceeds(submit(admin,'admin'));
  await assertFails(decide(admin,'admin','admin',true));
  await assertSucceeds(decide(owner,'owner','admin',true));
  assert.equal((await getDoc(doc(owner,path('members/admin')))).data().role,'member');
  assert.equal((await getDoc(doc(owner,path('movements/historical')))).data().amountCents,2050);
  assert.equal((await getDoc(doc(owner,path('persons/p')))).data().isActive,true);
});

test('Aprobación y rechazo: solicitud propia, gestión autorizada y miembro ligado a decisión', async () => {
  const owner=dbFor('owner');
  await configure(owner,'owner');
  await assertFails(submit(dbFor('waiting'),'waiting',{status:'approved'}));
  await assertSucceeds(submit(dbFor('waiting'),'waiting'));
  await assertSucceeds(getDoc(doc(dbFor('waiting'),path('joinRequests/waiting'))));
  await assertFails(getDoc(doc(dbFor('waiting'),'groups/a')));
  await assertFails(getDoc(doc(dbFor('other'),path('joinRequests/waiting'))));
  await assertFails(decide(dbFor('waiting'),'waiting','waiting',true));
  await assertFails(decide(owner,'owner','waiting',true,{role:'admin'}));
  await assertFails(decide(owner,'owner','waiting',true,{omitMember:true}));
  await assertSucceeds(decide(dbFor('admin'),'admin','waiting',true));
  await assertSucceeds(getDoc(doc(dbFor('waiting'),'groups/a')));
  await assertFails(decide(owner,'owner','waiting',false));
  await assertSucceeds(submit(dbFor('rejected'),'rejected'));
  await assertSucceeds(decide(owner,'owner','rejected',false));
  await assertFails(getDoc(doc(dbFor('rejected'),'groups/a')));
  await assertFails(deleteDoc(doc(owner,path('joinRequests/rejected'))));
  const events=await getDocs(collection(owner,path('auditEvents')));
  await assertFails(updateDoc(events.docs[0].ref,{after:{status:'forged'}}));
  await assertFails(deleteDoc(events.docs[0].ref));
});

test('Salir/expulsar conserva historial, revoca lectura y protege owner, grupos y campos', async () => {
  const owner=dbFor('owner'), member=dbFor('member'), admin=dbFor('admin');
  await assertFails(remove(owner,'owner','owner'));
  await assertFails(remove(member,'member','admin'));
  await assertFails(remove(dbFor('invalid-admin'),'invalid-admin','member'));
  await assertFails(remove(owner,'owner','member',{audit:false}));
  await assertFails(remove(owner,'owner','member',{patch:{personId:'p'}}));
  await assertSucceeds(remove(member,'member','member'));
  await assertFails(getDoc(doc(member,'groups/a')));
  await assertFails(getDocs(collection(member,path('movements'))));
  await assertSucceeds(remove(owner,'owner','admin'));
  const removed=(await getDoc(doc(owner,path('members/admin')))).data();
  assert.equal(removed.status,'inactive'); assert.equal(removed.role,'member'); assert.equal(removed.personId,'p');
  assert.equal((await getDoc(doc(owner,path('persons/p')))).data().isActive,true);
  assert.equal((await getDoc(doc(owner,path('movements/historical')))).data().amountCents,2050);
  await assertFails(getDocs(collection(admin,path('auditEvents'))));
  await assertFails(deleteDoc(doc(owner,path('members/admin'))));
});
