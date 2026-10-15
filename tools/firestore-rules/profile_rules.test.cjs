const { before, after, beforeEach, test } = require('node:test');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp } = require('firebase/firestore');

let environment;
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
  await assertSucceeds(updateDoc(reference, { displayName: 'Nuevo nombre', updatedAt: serverTimestamp(), lastSignInAt: serverTimestamp() }));
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
test('Los datos de grupos y colecciones globales siguen cerrados', async () => {
  const db = environment.authenticatedContext('alice').firestore();
  for (const path of ['groups/g1', 'groups/g1/members/alice', 'groups/g1/persons/p1', 'groups/g1/movements/m1', 'persons/p1', 'movements/m1', 'admins/alice']) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(setDoc(doc(db, path), { name: 'Sin permisos' }));
  }
});
