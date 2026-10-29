const {before,after,beforeEach,test}=require('node:test');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,getDocs,collection,writeBatch,serverTimestamp,Timestamp,deleteDoc,updateDoc,query,where,getAggregateFromServer,sum}=require('firebase/firestore');
let env;
const fresh=uid=>env.authenticatedContext(uid,{firebase:{sign_in_provider:'google.com'},auth_time:Math.floor(Date.now()/1000)}).firestore();
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-boteparroquial-lifecycle',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});});
after(async()=>{if(env)await env.cleanup();});
beforeEach(async()=>{await env.clearFirestore();await env.withSecurityRulesDisabled(async c=>{const s=c.firestore();await setDoc(doc(s,'groups/a'),{isActive:true,name:'DEMO grupo',createdBy:'owner'});for(const[uid,role]of[['owner','owner'],['admin','admin'],['member','member']])await setDoc(doc(s,`groups/a/members/${uid}`),{uid,role,status:'active',personId:null});await setDoc(doc(s,'groups/a/movements/history'),{amountCents:2050});});});
async function lock(s,uid,name='DEMO grupo') {const b=writeBatch(s),now=serverTimestamp();b.update(doc(s,'groups/a'),{isActive:false,deletionBy:uid,deletionName:name,deletionStartedAt:now,updatedBy:uid,updatedAt:now});b.set(doc(s,`users/${uid}/groupDeletionTasks/a`),{groupName:name,status:'deleting',createdAt:now});return b.commit();}

test('Agregados de caja autorizan miembros activos y rechazan otras cuentas o bajas',async()=>{
  await env.withSecurityRulesDisabled(async c=>{await setDoc(doc(c.firestore(),'groups/a/movements/history'),{type:'income',status:'active',amountCents:2050});});
  const aggregate=s=>getAggregateFromServer(query(collection(s,'groups/a/movements'),where('status','==','active'),where('type','==','income')),{total:sum('amountCents')});
  const result=await assertSucceeds(aggregate(fresh('member')));
  require('node:assert/strict').equal(result.data().total,2050);
  await assertFails(aggregate(fresh('outsider')));
  await env.withSecurityRulesDisabled(async c=>{await updateDoc(doc(c.firestore(),'groups/a/members/member'),{status:'inactive'});});
  await assertFails(aggregate(fresh('member')));
});
test('Solo owner con Google reciente, nombre exacto y tarea atómica puede bloquear',async()=>{
  await assertFails(lock(fresh('admin'),'admin'));await assertFails(lock(fresh('owner'),'owner','otro'));
  await assertFails(lock(env.authenticatedContext('owner',{firebase:{sign_in_provider:'google.com'},auth_time:1}).firestore(),'owner'));
  await assertSucceeds(lock(fresh('owner'),'owner'));
  await assertFails(getDoc(doc(fresh('member'),'groups/a/movements/history')));
  await assertSucceeds(getDoc(doc(fresh('owner'),'groups/a/movements/history')));
  await assertFails(deleteDoc(doc(fresh('owner'),'groups/a/movements/history')));
  await assertFails(updateDoc(doc(fresh('owner'),'groups/a'),{isActive:true}));
});
test('Eliminación madura queda ligada a su actor y al cierre atómico de la tarea',async()=>{
  await assertSucceeds(lock(fresh('owner'),'owner'));
  await env.withSecurityRulesDisabled(async c=>{await updateDoc(doc(c.firestore(),'groups/a'),{deletionStartedAt:Timestamp.fromMillis(Date.now()-181000)});});
  await assertFails(deleteDoc(doc(fresh('admin'),'groups/a/movements/history')));
  await assertSucceeds(deleteDoc(doc(fresh('owner'),'groups/a/movements/history')));
  await assertFails(deleteDoc(doc(fresh('owner'),'groups/a')));
  const owner=fresh('owner'),b=writeBatch(owner);b.delete(doc(owner,'groups/a'));b.update(doc(owner,'users/owner/groupDeletionTasks/a'),{status:'done'});await assertSucceeds(b.commit());
});
test('Baja bloquea acceso y nuevos dispositivos, permite limpiar solo la cuenta propia',async()=>{
  const s=fresh('member'),task=doc(s,'users/member/accountLifecycle/current');
  // The application withdraws memberships before sealing account closure.
  await env.withSecurityRulesDisabled(async c=>{await updateDoc(doc(c.firestore(),'groups/a/members/member'),{status:'inactive'});});
  await assertSucceeds(setDoc(task,{status:'preparing',groupIds:['a'],createdAt:serverTimestamp()}));
  await assertFails(getDoc(doc(s,'groups/a/movements/history')));
  await assertFails(setDoc(doc(s,`users/member/pushDevices/${'a'.repeat(64)}`),{token:'DEMO-delivery-token',platform:'android',createdAt:serverTimestamp(),updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(task,{status:'closing',closingAt:serverTimestamp(),groupIds:['a']}));
  await assertFails(deleteDoc(task));
  await assertFails(setDoc(doc(s,'groups/new'),{isActive:true,name:'nuevo'}));
  await assertSucceeds(getDoc(task));
  await assertFails(getDocs(collection(fresh('owner'),'users/member/accountLifecycle')));
});
