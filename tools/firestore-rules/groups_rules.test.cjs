const { before, after, test } = require('node:test');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, collectionGroup, query, where, getDoc, getDocs, setDoc, updateDoc, deleteDoc, Timestamp } = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-boteparroquial-groups', firestore: {
    rules: readFileSync(join(__dirname, '../../firestore.rules'), 'utf8') }});
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    const now = Timestamp.now();
    for (const group of ['a', 'b', 'closed']) {
      await setDoc(doc(db, `groups/${group}`), {name: group, isActive: group !== 'closed'});
    }
    for (const [group, uid, role, status] of [
      ['a','alice','owner','active'], ['a','bob','admin','active'],
      ['a','carol','member','active'], ['a','inactive','member','inactive'],
      ['b','outsider','owner','active'], ['closed','alice','owner','active'],
    ]) await setDoc(doc(db, `groups/${group}/members/${uid}`),
      {uid, displayName: uid, role, status, joinedAt: now, updatedAt: now});
  });
});
after(async () => { if (env) await env.cleanup(); });
test('Owner, admin y member activos leen su grupo y sus miembros', async () => {
  for (const uid of ['alice','bob','carol']) {
    const db = env.authenticatedContext(uid).firestore();
    await assertSucceeds(getDoc(doc(db, 'groups/a')));
    await assertSucceeds(getDocs(collection(db, 'groups/a/members')));
    await assertFails(getDoc(doc(db, 'groups/b')));
    await assertFails(getDocs(collection(db, 'groups/b/members')));
    await assertFails(getDocs(collection(db, 'groups')));
  }
});
test('Descubrimiento de membresías exige filtrar por el UID propio', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const result = await assertSucceeds(getDocs(query(collectionGroup(db, 'members'), where('uid', '==', 'alice'))));
  if (result.size !== 2) throw new Error('Deben encontrarse solo las dos membresías propias');
  await assertFails(getDocs(collectionGroup(db, 'members')));
  await assertFails(getDocs(query(collectionGroup(db, 'members'), where('uid', '==', 'bob'))));
  await assertFails(getDocs(query(collectionGroup(env.unauthenticatedContext().firestore(), 'members'), where('uid', '==', 'alice'))));
});
test('Sin sesión, sin membresía, inactivos y grupos cerrados no dan acceso', async () => {
  for (const db of [env.unauthenticatedContext().firestore(), env.authenticatedContext('outsider').firestore(), env.authenticatedContext('inactive').firestore()]) {
    await assertFails(getDoc(doc(db, 'groups/a')));
    await assertFails(getDoc(doc(db, 'groups/a/members/bob')));
  }
  await assertFails(getDoc(doc(env.authenticatedContext('alice').firestore(), 'groups/closed')));
});
test('Ningún cliente puede autopromoverse, editar al owner o crear/borrar grupos', async () => {
  for (const uid of ['alice','bob','carol','outsider']) {
    const db = env.authenticatedContext(uid).firestore();
    await assertFails(setDoc(doc(db, 'groups/new'), {name: 'Intrusión'}));
    await assertFails(updateDoc(doc(db, 'groups/a'), {currency: 'USD'}));
    await assertFails(deleteDoc(doc(db, 'groups/a')));
    await assertFails(setDoc(doc(db, `groups/a/members/${uid}`), {uid, role:'owner', status:'active'}));
    await assertFails(updateDoc(doc(db, 'groups/a/members/alice'), {role:'member'}));
    await assertFails(deleteDoc(doc(db, 'groups/a/members/alice')));
    for (const path of ['groups/a/auditEvents/e', 'persons/p','movements/m','admins/alice']) {
      await assertFails(getDoc(doc(db,path)));
      await assertFails(setDoc(doc(db,path),{value:1}));
    }
  }
});
test('Revocar una membresía corta las lecturas posteriores', async () => {
  const db = env.authenticatedContext('carol').firestore();
  await assertSucceeds(getDoc(doc(db,'groups/a')));
  await env.withSecurityRulesDisabled(context => updateDoc(doc(context.firestore(),'groups/a/members/carol'), {status:'inactive'}));
  await assertFails(getDoc(doc(db,'groups/a')));
  await assertFails(getDocs(collection(db,'groups/a/members')));
});
