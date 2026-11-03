const {before,beforeEach,after,test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc,updateDoc,deleteDoc,writeBatch,runTransaction,serverTimestamp,Timestamp}=require('firebase/firestore');
let env,seq=0;
const p=s=>`groups/a/${s}`,db=uid=>env.authenticatedContext(uid).firestore();
const month=2026*12+5;
const summary=d=>({movementId:d.movementId,personId:d.personId,month:d.month,amountCents:d.amountCents,revision:d.revision});
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-boteparroquial-allocations',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});});
after(async()=>{if(env)await env.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx=>{
    const s=ctx.firestore(),b=writeBatch(s),now=Timestamp.now();
    b.set(doc(s,'groups/a'),{isActive:true,timeZone:'Europe/Madrid'});
    b.set(doc(s,'groups/b'),{isActive:true});
    for(const[uid,role]of[['owner','owner'],['admin','admin'],['member','member']])
      b.set(doc(s,p(`members/${uid}`)),{uid,role,status:'active',personId:uid==='admin'?'admin-person':null});
    b.set(doc(s,p('persons/admin-person')),{isActive:true});
    b.set(doc(s,p('persons/person')),{displayName:'DEMO persona',notes:'',isActive:true,createdBy:'owner',updatedBy:'owner',createdAt:now,updatedAt:now});
    b.set(doc(s,p('participationPeriods/stage')),{personId:'person',firstMonth:month-1,lastMonthInclusive:null});
    b.set(doc(s,p('participationPeriods/other')),{personId:'other-person',firstMonth:month-1,lastMonthInclusive:null});
    b.set(doc(s,p('movements/income')),{type:'income',amountCents:5000,status:'active',personId:'person',description:'DEMO',occurredAt:Timestamp.fromDate(new Date(Date.UTC(2026,5,1))),createdBy:'owner',createdAt:now,updatedAt:now});
    b.set(doc(s,p('movements/withdrawal')),{type:'withdrawal',amountCents:1000,status:'active',personId:'person',description:'DEMO',occurredAt:Timestamp.fromDate(new Date(Date.UTC(2026,5,1))),createdBy:'owner',createdAt:now,updatedAt:now});
    await b.commit();
  });
});
function writes(s,actor,m,cents,old,balance,{source='income',omitBalance=false,omitAudit=false,extra={},balanceDelta=0,auditId}={}) {
  const id=`${source}_${m}`,event=auditId??`assign-${++seq}`,now=serverTimestamp();
  const data={movementId:source,personId:'person',month:m,amountCents:cents,revision:(old?.revision??0)+1,
    participationPeriodId:'stage',createdBy:old?.createdBy??actor,createdAt:old?.createdAt??now,updatedBy:actor,updatedAt:now,lastAuditEventId:event,...extra};
  return b=>{
    b.set(doc(s,p(`allocations/${id}`)),data);
    if(!omitBalance)b.set(doc(s,p(`allocationBalances/${source}`)),{allocatedCents:(balance?.allocatedCents??0)-(old?.amountCents??0)+cents+balanceDelta,revision:(balance?.revision??0)+1,lastAllocationId:id,lastAuditEventId:event,updatedBy:actor,updatedAt:now});
    if(!omitAudit)b.set(doc(s,p(`auditEvents/${event}`)),{action:'allocation.changed',entityType:'allocation',entityId:id,actorUid:actor,createdAt:now,before:old?summary(old):null,after:summary(data)});
  };
}
async function save(s,actor,m,cents,options={}) {
  const source=options.source??'income';
  const old=(await getDoc(doc(s,p(`allocations/${source}_${m}`)))).data();
  const balance=(await getDoc(doc(s,p(`allocationBalances/${source}`)))).data();
  const b=writeBatch(s);writes(s,actor,m,cents,old,balance,options)(b);return b.commit();
}
test('Ingreso nuevo y cuota en un commit: ambos o ninguno, sin relajar identidad ni permisos',async()=>{
  function combined(s,actor,id,cents,extra={}) {
    const now=serverTimestamp(),b=writeBatch(s);
    const data={type:'income',amountCents:300,status:'active',personId:'person',description:'DEMO ingreso y cuota',occurredAt:Timestamp.fromDate(new Date('2026-06-01T00:00:00Z')),createdBy:actor,createdAt:now,updatedAt:now};
    const after={type:data.type,amountCents:data.amountCents,personId:data.personId,occurredAt:data.occurredAt,description:data.description,status:data.status,correctionOfMovementId:null,correctedByMovementId:null,cancellationReason:null,correctionReason:null};
    b.set(doc(s,p(`movements/${id}`)),data);
    b.update(doc(s,p('persons/person')),{firstMovementId:id});
    b.set(doc(s,p(`auditEvents/movement-created-${id}`)),{action:'movement.created',entityType:'movement',entityId:id,actorUid:actor,createdAt:now,before:null,after});
    writes(s,actor,month,cents,null,null,{source:id,extra})(b);
    return b.commit();
  }
  const owner=db('owner');
  await assertSucceeds(combined(owner,'owner','new-income',100));
  assert.equal((await getDoc(doc(owner,p('movements/new-income')))).data().amountCents,300);
  assert.equal((await getDoc(doc(owner,p(`allocations/new-income_${month}`)))).data().amountCents,100);
  // A different person avoids rewriting an already established history witness.
  await env.withSecurityRulesDisabled(async ctx=>{await updateDoc(doc(ctx.firestore(),p('persons/person')),{firstMovementId:require('firebase/firestore').deleteField()});});
  await assertFails(combined(owner,'owner','excess',301));
  assert.equal((await getDoc(doc(owner,p('movements/excess')))).exists(),false);
  await assertFails(combined(owner,'owner','bad-period',100,{participationPeriodId:'other'}));
  assert.equal((await getDoc(doc(owner,p('movements/bad-period')))).exists(),false);
  await assertFails(combined(db('member'),'member','unauthorized-income',100));
});
test('Asignaciones con céntimos, permisos y auditoría inseparable; no alteran el ingreso',async()=>{
  await assertSucceeds(save(db('owner'),'owner',month,3000));
  await assertSucceeds(save(db('admin'),'admin',month+1,2000));
  assert.equal((await getDoc(doc(db('member'),p('allocationBalances/income')))).data().allocatedCents,5000);
  assert.equal((await getDoc(doc(db('member'),p('movements/income')))).data().amountCents,5000);
  await assertSucceeds(save(db('owner'),'owner',month,0));
  await assertFails(save(db('member'),'member',month,1));
  await assertFails(getDoc(doc(db('outsider'),p(`allocations/income_${month}`))));
  await assertFails(setDoc(doc(db('owner'),'groups/b/allocations/income_1'),{}));
  await assertFails(save(db('owner'),'owner',month,2000,{omitBalance:true}));
  await assertFails(save(db('owner'),'owner',month,2000,{omitAudit:true}));
  await assertFails(deleteDoc(doc(db('owner'),p(`allocations/income_${month}`))));
  const history=(await getDoc(doc(db('owner'),p(`allocations/income_${month}`)))).data().lastAuditEventId;
  await assertFails(updateDoc(doc(db('owner'),p(`auditEvents/${history}`)),{after:{amountCents:0}}));
});
test('No supera el ingreso ni falsifica contador, persona, etapa o tipo; acepta sobrepago mensual',async()=>{
  const owner=db('owner');
  for(const value of [-1,0,1.5,5001])await assertFails(save(owner,'owner',month,value));
  await assertFails(save(owner,'owner',month-2,1));
  await assertFails(save(owner,'owner',month,1,{extra:{participationPeriodId:'other'}}));
  await assertFails(save(owner,'owner',month,1,{source:'withdrawal'}));
  await assertFails(save(owner,'owner',month,1000,{balanceDelta:-1}));
  await assertFails(save(owner,'owner',month,1,{extra:{personId:'other-person'}}));
  await assertSucceeds(save(owner,'owner',month,4000)); // A month's fee is not a hard spending limit.
  await assertFails(save(owner,'owner',month+1,1001));
  await assertFails(setDoc(doc(owner,p('allocationBalances/income')),{allocatedCents:0,revision:2,lastAllocationId:`income_${month}`,lastAuditEventId:'forged',updatedBy:'owner',updatedAt:serverTimestamp()}));
  await assertFails(deleteDoc(doc(owner,p('allocationBalances/income'))));
});
test('Concurrencia no duplica fondos y dos asignaciones no comparten fraudulentamente un contador',async()=>{
  const owner=db('owner'),admin=db('admin');
  const make=(s,actor,m)=>runTransaction(s,async tx=>{
    const balance=(await tx.get(doc(s,p('allocationBalances/income')))).data();
    if((balance?.allocatedCents??0)+3000>5000)throw new Error('Insufficient unallocated income');
    writes(s,actor,m,3000,null,balance)(tx);
  });
  const results=await Promise.allSettled([make(owner,'owner',month),make(admin,'admin',month+1)]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  assert.equal((await getDoc(doc(owner,p('allocationBalances/income')))).data().allocatedCents,3000);
  const b=writeBatch(owner);
  writes(owner,'owner',month+2,1,null,{allocatedCents:3000,revision:1},{auditId:'one'})(b);
  writes(owner,'owner',month+3,1,null,{allocatedCents:3001,revision:2},{auditId:'two'})(b);
  await assertFails(b.commit());
});
test('Anular conserva reparto inmutable; no se puede asignar a ingresos anulados ni cerrar etapa y asignar fuera',async()=>{
  const owner=db('owner');await assertSucceeds(save(owner,'owner',month,2000));
  await assertSucceeds(updateDoc(doc(owner,p('movements/income')),{status:'cancelled',updatedAt:serverTimestamp(),cancelledAt:serverTimestamp(),cancelledBy:'owner',cancellationReason:'DEMO anulación'}));
  await assertFails(save(owner,'owner',month+1,1));
  await assertFails(save(owner,'owner',month,0));
  assert.equal((await getDoc(doc(db('member'),p(`allocations/income_${month}`)))).data().amountCents,2000);
  // Privileged fixture closure: tests payment eligibility after closing, not period rules again.
  await env.withSecurityRulesDisabled(async ctx=>{
    await updateDoc(doc(ctx.firestore(),p('participationPeriods/stage')),{lastMonthInclusive:month-1});
    await updateDoc(doc(ctx.firestore(),p('movements/income')),{status:'active'});
  });
  await assertFails(save(owner,'owner',month+1,1));
  await assertSucceeds(save(owner,'owner',month,0)); // Release a future payment after closing the period.
});
