const {before,beforeEach,after,test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc,updateDoc,writeBatch,runTransaction,serverTimestamp,Timestamp}=require('firebase/firestore');
let env,seq=0;
const p=s=>`groups/a/${s}`,db=uid=>env.authenticatedContext(uid).firestore();
const summary=d=>({uid:d.uid,personId:d.personId??null,role:d.role});
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-boteparroquial-member-links',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});});
after(async()=>{if(env)await env.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx=>{
    const store=ctx.firestore(),batch=writeBatch(store),now=Timestamp.now();
    batch.set(doc(store,'groups/a'),{isActive:true});batch.set(doc(store,'groups/b'),{isActive:true});
    for(const [id,uid,active]of[['owner-person','owner',true],['admin-person','admin',true],['free',null,true],['inactive',null,false],['historical','former',true]]) {
      batch.set(doc(store,p(`persons/${id}`)),{displayName:id,notes:null,isActive:active,linkedUid:uid,createdBy:'owner',updatedBy:'owner',createdAt:now,updatedAt:now});
    }
    for(const[uid,role,status,personId]of[['owner','owner','active','owner-person'],['admin','admin','active','admin-person'],['one','member','active',null],['two','member','active',null],['former','member','inactive','historical']]) {
      batch.set(doc(store,p(`members/${uid}`)),{uid,displayName:uid,role,status,personId,joinedAt:now,updatedAt:now});
    }
    batch.set(doc(store,p('movements/history')),{amountCents:2050,personId:'historical',status:'active'});
    await batch.commit();
  });
});
async function change(store,actor,uid,nextId,{omitOld=false,omitNew=false,omitAudit=false,roleOverride,forceClaim=false}={}) {
  return runTransaction(store,async tx=>{
    const member=doc(store,p(`members/${uid}`)),before=(await tx.get(member)).data();
    const old=before.personId?doc(store,p(`persons/${before.personId}`)):null;
    const next=nextId?doc(store,p(`persons/${nextId}`)):null;
    if(old)await tx.get(old);
    const person=next?(await tx.get(next)).data():null;
    if(person?.linkedUid!=null&&!forceClaim)throw new Error('Already linked');
    const now=serverTimestamp(),id=`link-${++seq}`;
    const after={...before,personId:nextId,role:roleOverride??(before.role==='admin'&&person?.isActive!==true?'member':before.role),updatedAt:now,lastAuditEventId:id};
    tx.set(member,after);
    if(old&&!omitOld)tx.update(old,{linkedUid:null,updatedBy:actor,updatedAt:now,lastAuditEventId:id});
    if(next&&!omitNew)tx.update(next,{linkedUid:uid,updatedBy:actor,updatedAt:now,lastAuditEventId:id});
    if(!omitAudit)tx.set(doc(store,p(`auditEvents/${id}`)),{action:'member.linkChanged',entityType:'member',entityId:uid,actorUid:actor,createdAt:now,before:summary(before),after:summary(after)});
  });
}
async function inactivate(store,actor,id,{omitMember=false,omitAudit=false}={}) {
  const ref=doc(store,p(`persons/${id}`)),before=(await getDoc(ref)).data();
  const member=before.linkedUid?doc(store,p(`members/${before.linkedUid}`)):null;
  const old=member?(await getDoc(member)).data():null;
  const now=serverTimestamp(),event=`state-${++seq}`,batch=writeBatch(store);
  batch.update(ref,{isActive:false,updatedBy:actor,updatedAt:now,lastAuditEventId:event});
  const role=old?.role==='admin'?'member':old?.role??null;
  if(old?.role==='admin'&&!omitMember)batch.update(member,{role:'member',updatedAt:now,lastAuditEventId:event});
  if(!omitAudit)batch.set(doc(store,p(`auditEvents/${event}`)),{action:'person.inactivated',entityType:'person',entityId:id,actorUid:actor,createdAt:now,
    before:{isActive:true,linkedUid:before.linkedUid??null,role:old?.role??null},after:{isActive:false,linkedUid:before.linkedUid??null,role}});
  return batch.commit();
}
test('Vínculos recíprocos, cambio/desvinculación auditados, persona inactiva y protección owner',async()=>{
  const owner=db('owner'),admin=db('admin');
  await assertFails(change(db('one'),'one','one','free'));
  await assertFails(change(owner,'owner','one','free',{omitNew:true}));
  await assertFails(change(owner,'owner','one','free',{omitAudit:true}));
  await assertSucceeds(change(owner,'owner','one','free'));
  await assertFails(change(owner,'owner','one','inactive',{omitOld:true}));
  await assertSucceeds(change(admin,'admin','one','inactive'));
  assert.equal((await getDoc(doc(owner,p('persons/free')))).data().linkedUid,null);
  assert.equal((await getDoc(doc(owner,p('persons/inactive')))).data().linkedUid,'one');
  await assertFails(change(admin,'admin','owner',null));
  await assertSucceeds(change(owner,'owner','owner',null));
  await assertFails(change(admin,'admin','admin',null,{roleOverride:'admin'}));
  await assertSucceeds(change(admin,'admin','admin',null));
  assert.equal((await getDoc(doc(owner,p('members/admin')))).data().role,'member');
  await assertFails(change(admin,'admin','two','free'));
  await assertFails(updateDoc(doc(owner,p('persons/free')),{linkedUid:'two',updatedBy:'owner',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(owner,p('members/two')),{personId:'free',role:'admin',updatedAt:serverTimestamp()}));
});
test('Concurrencia y reserva de vínculos históricos: no se trasladan ni duplican movimientos',async()=>{
  const owner=db('owner');
  const results=await Promise.allSettled(['one','two'].map(uid=>change(owner,'owner',uid,'free')));
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  await assertFails(change(owner,'owner','one','historical',{forceClaim:true}));
  await assertFails(change(owner,'owner','former','inactive'));
  await assertSucceeds(change(owner,'owner','former',null));
  await assertSucceeds(change(owner,'owner','one','historical'));
  const movement=(await getDoc(doc(owner,p('movements/history')))).data();
  assert.equal(movement.amountCents,2050);assert.equal(movement.personId,'historical');
  await assertFails(updateDoc(doc(db('outsider'),p('persons/historical')),{linkedUid:null,updatedBy:'outsider',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(owner,'groups/b/members/one'),{personId:'historical'}));
});
test('Inactivar degrada admin en el mismo commit, reactivar no lo asciende y los datos anteriores siguen editables',async()=>{
  const owner=db('owner'),admin=db('admin');
  await assertFails(inactivate(owner,'owner','admin-person',{omitMember:true}));
  await assertFails(inactivate(owner,'owner','admin-person',{omitAudit:true}));
  await assertSucceeds(inactivate(admin,'admin','admin-person'));
  assert.equal((await getDoc(doc(owner,p('members/admin')))).data().role,'member');
  await assertSucceeds(updateDoc(doc(owner,p('persons/admin-person')),{isActive:true,updatedBy:'owner',updatedAt:serverTimestamp()}));
  assert.equal((await getDoc(doc(owner,p('members/admin')))).data().role,'member');
  const now=serverTimestamp();
  await assertSucceeds(setDoc(doc(owner,p('persons/new')),{displayName:'Nueva',isActive:true,createdBy:'owner',updatedBy:'owner',createdAt:now,updatedAt:now}));
  await assertSucceeds(updateDoc(doc(owner,p('persons/new')),{notes:'Nota',updatedBy:'owner',updatedAt:serverTimestamp()}));
  await assertSucceeds(inactivate(owner,'owner','new'));
  await assertFails(updateDoc(doc(owner,p('persons/new')),{lastAuditEventId:'invented',updatedAt:serverTimestamp(),updatedBy:'owner'}));
  await assertFails(updateDoc(doc(owner,p('members/one')),{role:'admin',updatedAt:serverTimestamp()}));
});
