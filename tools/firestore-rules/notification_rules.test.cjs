const {before, after, beforeEach, test} = require('node:test');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, collection, getDoc, getDocs, query, where, orderBy, limit, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp} = require('firebase/firestore');
let env;
const deviceId = 'a'.repeat(64);
const now = Timestamp.fromMillis(1000);
before(async () => {
  env = await initializeTestEnvironment({projectId:'demo-boteparroquial',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx => {
    const db=ctx.firestore();
    for(const g of ['a','b']) {
      await setDoc(doc(db,`groups/${g}`),{isActive:true});
      await setDoc(doc(db,`groups/${g}/members/alice`),{uid:'alice',status:g==='a'?'active':'inactive',role:'member'});
      await setDoc(doc(db,`groups/${g}/notifications/one`),{recipientUid:'alice',kind:'quotaReminder',title:'DEMO',body:'DEMO',createdAt:now,readAt:null});
    }
    await setDoc(doc(db,'groups/a/notifications/other'),{recipientUid:'bob',kind:'quotaReminder',title:'DEMO',body:'DEMO',createdAt:now,readAt:null});
  });
});
after(async () => { if(env) await env.cleanup(); });
test('Dispositivos privados: dueño, campos, fechas y retirada sin pertenencia al grupo',async()=>{
  const alice=env.authenticatedContext('alice').firestore(),bob=env.authenticatedContext('bob').firestore();
  const path=`users/alice/pushDevices/${deviceId}`;
  const data={token:'DEMO-token-1234567890',platform:'android',createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(alice,path),data));
  await assertSucceeds(getDoc(doc(alice,path)));
  await assertFails(getDoc(doc(bob,path)));
  await assertFails(setDoc(doc(bob,path),data));
  await assertFails(updateDoc(doc(alice,path),{role:'owner',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(alice,path),{createdAt:now,updatedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(alice,'users/alice/pushDevices/invalid'),data));
  await assertSucceeds(deleteDoc(doc(alice,path)));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(),path),data));
});
test('Bandeja: consulta acotada propia; sin falsificación, borrado o lectura cruzada',async()=>{
  const db=env.authenticatedContext('alice').firestore();
  const inbox=collection(db,'groups/a/notifications');
  await assertSucceeds(getDocs(query(inbox,where('recipientUid','==','alice'),orderBy('createdAt','desc'),limit(50))));
  await assertFails(getDocs(query(inbox,limit(50))));
  await assertFails(getDocs(query(inbox,where('recipientUid','==','alice'),limit(51))));
  await assertFails(getDoc(doc(db,'groups/a/notifications/other')));
  await assertFails(getDoc(doc(db,'groups/b/notifications/one')));
  await assertFails(setDoc(doc(db,'groups/a/notifications/forged'),{recipientUid:'alice',title:'DEMO'}));
  const own=doc(db,'groups/a/notifications/one');
  await assertFails(updateDoc(own,{body:'Forged',readAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(own,{readAt:serverTimestamp()}));
  await assertFails(updateDoc(own,{readAt:null}));
  await assertFails(deleteDoc(own));
  await env.withSecurityRulesDisabled(ctx=>updateDoc(doc(ctx.firestore(),'groups/a'),{isActive:false}));
  await assertFails(getDoc(own));
});
test('Preferencias: solo la membresía propia activa, no roles ni preferencias ajenas',async()=>{
  const db=env.authenticatedContext('alice').firestore();
  const data={quotaPushEnabled:false,updatedAt:serverTimestamp()};
  const own=doc(db,'groups/a/members/alice/notificationPreferences/reminders');
  await assertSucceeds(getDoc(own));
  await assertSucceeds(setDoc(own,data));
  await assertSucceeds(updateDoc(own,{quotaPushEnabled:true,updatedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(db,'groups/a/members/bob/notificationPreferences/reminders'),data));
  await assertFails(setDoc(doc(db,'groups/b/members/alice/notificationPreferences/reminders'),data));
  await assertFails(updateDoc(own,{role:'owner',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(own,{updatedAt:now}));
  await assertFails(deleteDoc(own));
  for (const category of ['economic','informative']) {
    const preference=doc(db,`groups/a/members/alice/notificationPreferences/${category}`);
    await assertSucceeds(setDoc(preference,{pushEnabled:false,updatedAt:serverTimestamp()}));
    await assertSucceeds(getDoc(preference));
    await assertFails(setDoc(doc(db,`groups/a/members/bob/notificationPreferences/${category}`),{pushEnabled:true,updatedAt:serverTimestamp()}));
    await assertFails(updateDoc(preference,{role:'owner',updatedAt:serverTimestamp()}));
    await assertFails(updateDoc(preference,{updatedAt:now}));
  }
});
