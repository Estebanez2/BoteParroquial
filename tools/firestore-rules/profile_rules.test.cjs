const { before, after, beforeEach, test } = require('node:test');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp,writeBatch } = require('firebase/firestore');

let environment;
let eventSequence=0;
async function rename(db,uid,name,extra={}) {
  const ref=doc(db,`users/${uid}`),before=(await getDoc(ref)).data(),id=`rename-${++eventSequence}`,now=serverTimestamp(),batch=writeBatch(db);
  batch.update(ref,{displayName:name,updatedAt:now,lastAuditEventId:id,...extra});
  batch.set(doc(db,`users/${uid}/auditEvents/${id}`),{action:'profile.renamed',entityType:'profile',entityId:uid,actorUid:uid,createdAt:now,before:{displayName:before.displayName},after:{displayName:name}});
  return batch.commit();
}
const profile = () => ({ displayName: 'Usuario de prueba', email: null, photoUrl: null,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), lastSignInAt: serverTimestamp() });
before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-boteparroquial',
    firestore: { rules: readFileSync(join(__dirname, '../../firestore.rules'), 'utf8') },
  });
});
beforeEach(async () => environment.clearFirestore());
after(async () => { if (environment) await environment.cleanup(); });

test('Un usuario crea, lee y actualiza únicamente su perfil', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  const reference = doc(db, 'users/alice');
  await assertSucceeds(setDoc(reference, profile()));
  await assertSucceeds(getDoc(reference));
  await assertFails(updateDoc(reference, {displayName:'Sin auditoría',updatedAt:serverTimestamp()}));
  await assertSucceeds(rename(db,'alice','Nuevo nombre',{lastSignInAt:serverTimestamp()}));
});
test('Usuarios anónimos y otras cuentas no leen ni escriben perfiles ajenos', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  await setDoc(doc(alice, 'users/alice'), profile());
  for (const db of [environment.unauthenticatedContext().firestore(), environment.authenticatedContext('bob').firestore()]) {
    await assertFails(getDoc(doc(db, 'users/alice')));
    await assertFails(setDoc(doc(db, 'users/alice'), profile()));
    await assertFails(updateDoc(doc(db, 'users/alice'), { displayName: 'Intruso', updatedAt: serverTimestamp(), lastSignInAt: serverTimestamp() }));
  }
});
test('No se permite listar, borrar, añadir roles ni falsificar fechas/tipos', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  const reference = doc(db, 'users/alice');
  await assertFails(setDoc(reference, { ...profile(), role: 'admin' }));
  await assertFails(setDoc(reference, { ...profile(), displayName: 25 }));
  await assertFails(setDoc(reference, { ...profile(), createdAt: Timestamp.fromMillis(1) }));
  await assertSucceeds(setDoc(reference, profile()));
  await assertFails(getDocs(collection(db, 'users')));
  await assertFails(deleteDoc(reference));
  await assertFails(updateDoc(reference, { createdAt: Timestamp.fromMillis(1), updatedAt: serverTimestamp(), lastSignInAt: serverTimestamp() }));
  await assertFails(updateDoc(reference, { role: 'owner', updatedAt: serverTimestamp(), lastSignInAt: serverTimestamp() }));
});
test('Los datos de grupos ajenos y colecciones globales siguen cerrados', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  await environment.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(), 'groups/g1'), {isActive: true}));
  for (const path of ['groups/g1', 'groups/g1/members/bob', 'groups/g1/persons/p1', 'groups/g1/movements/m1', 'persons/p1', 'movements/m1', 'admins/alice']) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(setDoc(doc(db, path), { name: 'Sin permisos' }));
  }
});

test('Editar nombre conserva el último acceso y no permite inventar fechas o nombres vacíos', async () => {
  const db = environment.authenticatedContext('alice').firestore(), reference = doc(db, 'users/alice');
  await setDoc(reference, profile());
  const before = (await getDoc(reference)).data();
  await assertSucceeds(rename(db,'alice','Nombre propio'));
  const after = (await getDoc(reference)).data();
  if (!before.lastSignInAt.isEqual(after.lastSignInAt)) throw new Error('Editar no debe inventar un inicio de sesión');
  await assertFails(updateDoc(reference, {displayName: '   ', updatedAt: serverTimestamp()}));
  await assertFails(updateDoc(reference, {lastSignInAt: Timestamp.fromMillis(1), updatedAt: serverTimestamp()}));
});
