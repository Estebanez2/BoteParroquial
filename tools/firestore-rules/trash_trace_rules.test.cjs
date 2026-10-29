const {before,after,beforeEach,test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,writeBatch,serverTimestamp,Timestamp,deleteField,updateDoc,deleteDoc}=require('firebase/firestore');
let env,sequence=0;
const p=s=>`groups/a/${s}`;
const person=(extra={})=>({displayName:'DEMO persona',notes:null,isActive:true,historyGuardVersion:1,createdBy:'owner',updatedBy:'owner',createdAt:Timestamp.fromMillis(1),updatedAt:Timestamp.fromMillis(1),...extra});
const identity=d=>({displayName:d.displayName,notes:d.notes??null,isActive:d.isActive});
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-boteparroquial-trash',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});});
after(async()=>{if(env)await env.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore(); await env.withSecurityRulesDisabled(async c=>{
    const s=c.firestore();await setDoc(doc(s,'groups/a'),{isActive:true,timeZone:'Europe/Madrid'});
    for(const[uid,role]of[['owner','owner'],['member','member']])await setDoc(doc(s,p(`members/${uid}`)),{uid,role,status:'active',personId:null});
    for(const[id,extra]of[['empty',{}],['history',{}],['period',{lastParticipationPeriodId:'old'}],['linked',{linkedUid:'member'}],['legacy',{}]]) {
      const data=person(extra); if(id==='legacy')delete data.historyGuardVersion;
      await setDoc(doc(s,p(`persons/${id}`)),data);
    }
    await updateDoc(doc(s,p('persons/history')),{firstMovementId:'old'});
    await setDoc(doc(s,p('persons/expired')),person({isActive:false,trashedAt:Timestamp.fromMillis(Date.now()-11*86400000),trashedBy:'owner',trashedWasActive:true}));
  });
});
function actor(uid='owner'){return env.authenticatedContext(uid).firestore();}
async function change(s,id,operation,patch={}){
  const ref=doc(s,p(`persons/${id}`)),before=(await getDoc(ref)).data(),event=`change-${++sequence}`,now=serverTimestamp();
  const fields=operation==='trashed'?{isActive:false,trashedAt:now,trashedBy:'owner',trashedWasActive:before.isActive}:
    {isActive:before.trashedWasActive,trashedAt:deleteField(),trashedBy:deleteField(),trashedWasActive:deleteField()};
  const after=identity({...before,...fields,...patch}),b=writeBatch(s);
  b.update(ref,{...fields,...patch,updatedBy:'owner',updatedAt:now,lastAuditEventId:event});
  b.set(doc(s,p(`auditEvents/${event}`)),{action:`person.${operation}`,entityType:'person',entityId:id,actorUid:'owner',createdAt:now,before:identity(before),after});
  return b.commit();
}
test('Papelera: historial, vínculo y legado bloqueados; restauración conserva estado y fecha servidor',async()=>{
  const s=actor();
  for(const id of ['history','period','linked','legacy'])await assertFails(change(s,id,'trashed'));
  await assertSucceeds(change(s,'empty','trashed'));
  await assertFails(updateDoc(doc(s,p('persons/empty')),{notes:'editar oculto',updatedAt:serverTimestamp(),updatedBy:'owner'}));
  await assertSucceeds(change(s,'empty','restored'));
  assert.equal((await getDoc(doc(s,p('persons/empty')))).data().isActive,true);
  await assertFails(change(s,'expired','restored'));
  await assertFails(change(actor('member'),'empty','trashed'));
});
test('Purgar exige diez días, ausencia de historial y evento nuevo atómico',async()=>{
  const s=actor();await assertSucceeds(change(s,'empty','trashed'));
  async function purge(id){await updateDoc(doc(s,p(`persons/${id}`)),{purgingAt:serverTimestamp()});const b=writeBatch(s),before=(await getDoc(doc(s,p(`persons/${id}`)))).data();b.delete(doc(s,p(`persons/${id}`)));b.set(doc(s,p(`auditEvents/person-purged-${id}`)),{action:'person.purged',entityType:'person',entityId:id,actorUid:'owner',createdAt:serverTimestamp(),before:identity(before),after:null});return b.commit();}
  await assertFails(deleteDoc(doc(s,p('persons/expired'))));
  await assertFails(purge('empty'));await assertSucceeds(purge('expired'));
});
const movementIdentity=d=>Object.fromEntries(['type','amountCents','personId','occurredAt','description','status','correctionOfMovementId','correctedByMovementId','cancellationReason','correctionReason'].map(k=>[k,d[k]??null]));
test('Movimiento y auditoría son atómicos; testigo inmutable impide papelera y carrera',async()=>{
  const s=actor();
  async function income(id,{guard=true,audit=true}={}){
    const now=serverTimestamp(),day=new Date();day.setUTCHours(0,0,0,0);
    const data={type:'income',amountCents:2050,status:'active',personId:'empty',occurredAt:Timestamp.fromDate(day),description:'DEMO ingreso',createdBy:'owner',createdAt:now,updatedAt:now};
    const b=writeBatch(s);b.set(doc(s,p(`movements/${id}`)),data);
    if(guard)b.update(doc(s,p('persons/empty')),{firstMovementId:id});
    if(audit)b.set(doc(s,p(`auditEvents/movement-created-${id}`)),{action:'movement.created',entityType:'movement',entityId:id,actorUid:'owner',createdAt:now,before:null,after:movementIdentity(data)});
    return b.commit();
  }
  await assertFails(income('missing-audit',{audit:false}));await assertFails(income('missing-guard',{guard:false}));
  await assertSucceeds(income('valid'));await assertFails(change(s,'empty','trashed'));
  await assertFails(updateDoc(doc(s,p('persons/empty')),{firstMovementId:deleteField()}));
});
