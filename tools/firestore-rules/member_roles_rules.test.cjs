const {before,beforeEach,after,test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,getDoc,writeBatch,serverTimestamp,Timestamp}=require('firebase/firestore');
let env,seq=0;
const p=s=>`groups/a/${s}`;
const db=(uid,age=0)=>env.authenticatedContext(uid,{auth_time:Math.floor(Date.now()/1000)-age,firebase:{sign_in_provider:'google.com'}}).firestore();
const summary=d=>({uid:d.uid,personId:d.personId??null,role:d.role});
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-boteparroquial-member-roles',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});});
after(async()=>{if(env)await env.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx=>{
    const store=ctx.firestore(),batch=writeBatch(store),now=Timestamp.now();
    batch.set(doc(store,'groups/a'),{name:'DEMO Roles',description:null,currency:'EUR',timeZone:'Europe/Madrid',isActive:true,createdBy:'owner',updatedBy:'owner',createdAt:now,updatedAt:now,lastAuditEventId:'created'});
    batch.set(doc(store,'groups/b'),{isActive:true});
    for(const [uid,role,status,active] of [['owner','owner','active',true],['admin','admin','active',true],['one','member','active',true],['two','member','active',true],['inactive','member','active',false],['former','member','inactive',true]]) {
      batch.set(doc(store,p(`members/${uid}`)),{uid,displayName:uid,role,status,personId:uid,joinedAt:now,updatedAt:now});
      batch.set(doc(store,p(`persons/${uid}`)),{displayName:uid,isActive:active,linkedUid:uid,createdBy:'owner',updatedBy:'owner',createdAt:now,updatedAt:now});
    }
    batch.set(doc(store,p('members/unlinked')),{uid:'unlinked',displayName:'unlinked',role:'member',status:'active',personId:null,joinedAt:now,updatedAt:now});
    batch.set(doc(store,p('movements/history')),{amountCents:2050,personId:'owner',status:'active'});
    await batch.commit();
  });
});
async function role(store,actor,uid,next,{omitAudit=false,extra={},after={}}={}) {
  const ref=doc(store,p(`members/${uid}`)),old=(await getDoc(ref)).data();
  const id=`role-${++seq}`,now=serverTimestamp(),batch=writeBatch(store);
  const data={...old,role:next,...extra};
  batch.update(ref,{role:next,updatedAt:now,lastAuditEventId:id,...extra});
  if(!omitAudit)batch.set(doc(store,p(`auditEvents/${id}`)),{action:'member.roleChanged',entityType:'member',entityId:uid,actorUid:actor,createdAt:now,before:summary(old),after:{...summary(data),...after}});
  return batch.commit();
}
async function transfer(store,actor,recipient,{omitFormer=false,omitNext=false,omitGroup=false,omitAudit=false,formerRole='member',name='DEMO Roles',extraNext={},extraGroup={},extraMember}={}) {
  const batch=writeBatch(store),id=`transfer-${++seq}`,now=serverTimestamp();
  if(!omitFormer)batch.update(doc(store,p(`members/${actor}`)),{role:formerRole,updatedAt:now,lastAuditEventId:id});
  if(!omitNext)batch.update(doc(store,p(`members/${recipient}`)),{role:'owner',updatedAt:now,lastAuditEventId:id,...extraNext});
  if(!omitGroup)batch.update(doc(store,'groups/a'),{updatedAt:now,updatedBy:actor,lastAuditEventId:id,...extraGroup});
  if(extraMember)batch.update(doc(store,p(`members/${extraMember}`)),{role:'owner',updatedAt:now,lastAuditEventId:id});
  if(!omitAudit)batch.set(doc(store,p(`auditEvents/${id}`)),{action:'group.ownershipTransferred',entityType:'group',entityId:'a',actorUid:actor,createdAt:now,before:{ownerUid:actor,groupName:name},after:{ownerUid:recipient,groupName:name}});
  return batch.commit();
}
test('Roles: gestión autorizada, persona activa, protección owner y auditoría exacta',async()=>{
  const owner=db('owner'),admin=db('admin');
  await assertFails(role(db('one'),'one','one','admin'));
  await assertFails(role(owner,'owner','owner','member'));
  await assertFails(role(admin,'admin','owner','member'));
  await assertFails(role(owner,'owner','inactive','admin'));
  await assertFails(role(owner,'owner','unlinked','admin'));
  await assertFails(role(owner,'owner','former','admin'));
  await assertFails(role(owner,'owner','one','admin',{omitAudit:true}));
  await assertFails(role(owner,'owner','one','admin',{extra:{displayName:'Alterado'}}));
  await assertFails(role(owner,'owner','one','admin',{after:{personId:'two'}}));
  await assertSucceeds(role(admin,'admin','one','admin'));
  await assertSucceeds(role(db('one'),'one','admin','member'));
  await assertFails(role(admin,'admin','two','admin'));
  await assertSucceeds(role(db('one'),'one','one','member'));
  await assertFails(role(owner,'owner','two','owner'));
});
test('Transferencia: Google reciente, destinatario válido y commit completo sin alterar historia',async()=>{
  const owner=db('owner');
  await assertFails(transfer(env.authenticatedContext('owner',{auth_time:Math.floor(Date.now()/1000),firebase:{sign_in_provider:'password'}}).firestore(),'owner','one'));
  await assertFails(transfer(db('owner',600),'owner','one'));
  await assertFails(transfer(db('owner',-600),'owner','one'));
  await assertFails(transfer(db('admin'),'admin','one'));
  await assertFails(transfer(owner,'owner','unlinked'));
  await assertFails(transfer(owner,'owner','inactive'));
  await assertFails(transfer(owner,'owner','former'));
  for(const options of [{omitFormer:true},{omitNext:true},{omitGroup:true},{omitAudit:true},{formerRole:'admin'},{name:'Nombre equivocado'},{extraMember:'two'},{extraNext:{personId:'two'}},{extraGroup:{createdBy:'one'}}]) {
    await assertFails(transfer(owner,'owner','one',options));
  }
  const old=(await getDoc(doc(owner,p('members/owner')))).data();
  await assertSucceeds(transfer(owner,'owner','one'));
  const former=(await getDoc(doc(owner,p('members/owner')))).data();
  const next=(await getDoc(doc(owner,p('members/one')))).data();
  assert.equal(former.role,'member'); assert.equal(next.role,'owner');
  assert.equal(former.personId,old.personId);assert.ok(former.joinedAt.isEqual(old.joinedAt));
  assert.equal((await getDoc(doc(owner,'groups/a'))).data().createdBy,'owner');
  assert.equal((await getDoc(doc(owner,p('movements/history')))).data().amountCents,2050);
  await assertFails(role(owner,'owner','admin','member'));
  await assertFails(transfer(owner,'owner','two'));
  await assertSucceeds(role(db('one'),'one','two','admin'));
  await assertSucceeds(transfer(db('one'),'one','admin'));
});
test('Concurrencia: dos transferencias no dejan dos propietarios y rechaza cambios combinados de persona',async()=>{
  const owner=db('owner');
  const results=await Promise.allSettled(['one','two'].map(uid=>transfer(owner,'owner',uid)));
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  const roles=await Promise.all(['owner','one','two','admin'].map(uid=>getDoc(doc(owner,p(`members/${uid}`)))));
  assert.equal(roles.filter(row=>row.data().role==='owner').length,1);
  const winner=roles.find(row=>row.data().role==='owner').id;
  const store=db(winner),batch=writeBatch(store),id=`mixed-${++seq}`,now=serverTimestamp();
  const target=winner==='one'?'two':'one';
  const member=(await getDoc(doc(store,p(`members/${target}`)))).data();
  batch.update(doc(store,p(`members/${target}`)),{role:'admin',updatedAt:now,lastAuditEventId:id});
  batch.update(doc(store,p(`persons/${target}`)),{isActive:false,updatedAt:now,updatedBy:winner,lastAuditEventId:id});
  batch.set(doc(store,p(`auditEvents/${id}`)),{action:'member.roleChanged',entityType:'member',entityId:target,actorUid:winner,createdAt:now,before:summary(member),after:{...summary(member),role:'admin'}});
  await assertFails(batch.commit());
});
