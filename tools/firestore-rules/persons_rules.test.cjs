const {before,after,test} = require('node:test');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails} = require('@firebase/rules-unit-testing');
const {doc,collection,getDoc,getDocs,setDoc,updateDoc,deleteDoc,serverTimestamp,Timestamp} = require('firebase/firestore');
let env;
const data = uid => ({displayName:'Persona de prueba',notes:null,isActive:true,createdBy:uid,updatedBy:uid,
  createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
before(async()=>{
  env = await initializeTestEnvironment({projectId:'demo-boteparroquial-persons',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});
  await env.withSecurityRulesDisabled(async context=>{
    const db = context.firestore();
    await setDoc(doc(db,'groups/a'),{isActive:true});
    await setDoc(doc(db,'groups/b'),{isActive:true});
    await setDoc(doc(db,'groups/a/persons/admin-person'),data('owner'));
    for (const [uid,role,status,personId] of [
      ['owner','owner','active',null],['admin','admin','active','admin-person'],
      ['member','member','active',null],['inactive','owner','inactive',null],['unlinked','admin','active',null],
    ]) await setDoc(doc(db,`groups/a/members/${uid}`),{uid,role,status,personId});
  });
});
after(async()=>{if(env)await env.cleanup();});
test('Owner y admin: crear, editar, inactivar, reactivar conservando historial; nunca borrar',async()=>{
  for(const uid of ['owner','admin']) {
    const db = env.authenticatedContext(uid).firestore();
    const ref = doc(db,`groups/a/persons/${uid}-new`);
    await assertSucceeds(setDoc(ref,data(uid)));
    const original = (await getDoc(ref)).data();
    await assertSucceeds(updateDoc(ref,{displayName:'Nombre editado',notes:'Una nota',updatedBy:uid,updatedAt:serverTimestamp()}));
    await assertSucceeds(updateDoc(ref,{isActive:false,updatedBy:uid,updatedAt:serverTimestamp()}));
    await assertSucceeds(updateDoc(ref,{isActive:true,updatedBy:uid,updatedAt:serverTimestamp()}));
    const edited = (await getDoc(ref)).data();
    if(!edited.createdAt.isEqual(original.createdAt)||edited.createdBy!==original.createdBy)throw new Error('Metadatos históricos alterados');
    await assertFails(deleteDoc(ref));
  }
  const owner = env.authenticatedContext('owner').firestore();
  await updateDoc(doc(owner,'groups/a/persons/admin-person'),{isActive:false,updatedBy:'owner',updatedAt:serverTimestamp()});
  await assertFails(setDoc(doc(env.authenticatedContext('admin').firestore(),'groups/a/persons/forbidden'),data('admin')));
});
test('Miembros solo leen; sin membresía, inactivos, anónimos y otros grupos quedan aislados',async()=>{
  const member = env.authenticatedContext('member').firestore();
  await assertSucceeds(getDocs(collection(member,'groups/a/persons')));
  await assertFails(setDoc(doc(member,'groups/a/persons/forbidden'),data('member')));
  await assertFails(updateDoc(doc(member,'groups/a/persons/owner-new'),{isActive:false,updatedBy:'member',updatedAt:serverTimestamp()}));
  for(const uid of ['owner','admin','member','outsider','inactive','unlinked']) {
    const db = env.authenticatedContext(uid).firestore();
    await assertFails(getDocs(collection(db,'groups/b/persons')));
    await assertFails(setDoc(doc(db,'groups/b/persons/forbidden'),data(uid)));
  }
  for(const db of [env.unauthenticatedContext().firestore(),env.authenticatedContext('outsider').firestore(),env.authenticatedContext('inactive').firestore()]) {
    await assertFails(getDocs(collection(db,'groups/a/persons')));
  }
  await assertFails(setDoc(doc(env.authenticatedContext('unlinked').firestore(),'groups/a/persons/forbidden'),data('unlinked')));
});
test('Rules validan autor, fechas, tipos, límites y campos; dinero sigue cerrado',async()=>{
  const db = env.authenticatedContext('owner').firestore();
  const ref = doc(db,'groups/a/persons/validation');
  for(const patch of [{displayName:'   '},{displayName:'x'.repeat(257)},{notes:'x'.repeat(2001)},
    {isActive:'true'},{createdBy:'other'},{updatedBy:'other'},{createdAt:Timestamp.fromMillis(1)},
    {updatedAt:Timestamp.fromMillis(1)},{role:'owner'}]) {
    await assertFails(setDoc(ref,{...data('owner'),...patch}));
  }
  await assertSucceeds(setDoc(ref,data('owner')));
  await assertFails(updateDoc(ref,{createdBy:'other',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref,{createdAt:Timestamp.fromMillis(1),updatedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(db,'groups/a/movements/m'),{amountCents:100}));
});
