const {before,beforeEach,after,test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc,updateDoc,deleteDoc,writeBatch,serverTimestamp,Timestamp}=require('firebase/firestore');
let env,seq=0;
const p=s=>`groups/a/${s}`,db=uid=>env.authenticatedContext(uid).firestore(),months=[24316,24317,24318,24319];
const assigned=plan=>Object.values(plan?.parts??{}).reduce((sum,v)=>sum+v,0);
const total=plan=>(plan?.unallocatedCents??0)+assigned(plan);
const at=(plan,month)=>plan?.parts[month]??0;
const plan=(parts=[],unallocatedCents=0,incomeId='income')=>({incomeId,unallocatedCents,parts:Object.fromEntries(parts.map(([month,cents])=>[String(month),cents]))});
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-boteparroquial-refunds',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});});
after(async()=>{if(env)await env.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore();await env.withSecurityRulesDisabled(async ctx=>{
    const s=ctx.firestore(),b=writeBatch(s),now=Timestamp.now(),date=new Date();date.setUTCHours(0,0,0,0);
    b.set(doc(s,'groups/a'),{isActive:true,timeZone:'Europe/Madrid'});
    for(const[uid,role]of[['owner','owner'],['admin','admin'],['member','member']])b.set(doc(s,p(`members/${uid}`)),{uid,role,status:'active',personId:uid==='admin'?'admin-person':null});
    b.set(doc(s,p('persons/admin-person')),{isActive:true});b.set(doc(s,p('persons/person')),{isActive:true,historyGuardVersion:1,firstMovementId:'income'});
    for(const[id,personId]of[['income','person'],['other','another-person'],['cash','person']])b.set(doc(s,p(`movements/${id}`)),{type:'income',amountCents:10000,status:'active',personId,description:'DEMO ingreso',occurredAt:Timestamp.fromDate(date),createdBy:'owner',createdAt:now,updatedAt:now});
    b.set(doc(s,p('allocationBalances/income')),{allocatedCents:8000,revision:1,lastAllocationId:`income_${months[3]}`,lastAuditEventId:'seed',updatedBy:'owner',updatedAt:now});
    for(const month of [...months,24320])b.set(doc(s,p(`allocations/income_${month}`)),{movementId:'income',personId:'person',month,amountCents:month===24320?0:2000,revision:1,
      participationPeriodId:'stage',createdBy:'owner',createdAt:now,updatedBy:'owner',updatedAt:now,lastAuditEventId:'seed'});
    b.set(doc(s,p('participationPeriods/stage')),{personId:'person',firstMonth:months[0],lastMonthInclusive:null});
    await b.commit();
  });
});
async function transition(s,actor,{next,originalId,cancel=false,id=`return-${++seq}`,omitRow=false,omitBalance=false,omitOperation=false,extra={},extraBalance={},extraOperation={}}={}){
  const original=originalId?(await getDoc(doc(s,p(`movements/${originalId}`)))).data():null;
  const old=original?.refund??null,source=old?.incomeId??next?.incomeId;
  const balance=(await getDoc(doc(s,p(`allocationBalances/${source}`)))).data();
  const income=(await getDoc(doc(s,p(`movements/${source}`)))).data();
  const kind=originalId?(cancel?'cancel':'correct'):'create',opId=cancel?`refund-cancel-${originalId}`:`refund-${id}`;
  const all=[...new Set([...Object.keys(old?.parts??{}),...Object.keys(next?.parts??{})])].sort();
  const now=serverTimestamp(),changes=[],rows=[];
  for(const month of all){
    const rowId=`${source}_${month}`,before=(await getDoc(doc(s,p(`allocations/${rowId}`)))).data();
    changes.push(month);
    rows.push([rowId,before]);
  }
  const op={kind,incomeId:source,originalMovementId:originalId??null,targetMovementId:cancel?null:id,
    previousAmountCents:total(old),amountCents:total(next),previousAssignedCents:assigned(old),assignedCents:assigned(next),changes,previousRefund:old,refund:next??null,actorUid:actor,createdAt:now};
  const b=writeBatch(s);
  if(originalId)b.update(doc(s,p(`movements/${originalId}`)),{status:cancel?'cancelled':'corrected',updatedAt:now,lastRefundOperationId:opId,
    ...(cancel?{cancelledBy:actor,cancelledAt:now,cancellationReason:'DEMO anulación'}:{correctedBy:actor,correctedAt:now,correctionReason:'DEMO corrección',correctedByMovementId:id})});
  if(!cancel)b.set(doc(s,p(`movements/${id}`)),{type:'withdrawal',amountCents:next?total(next):1000,status:'active',personId:'person',description:'DEMO devolución',
    occurredAt:income.occurredAt,createdBy:actor,createdAt:now,updatedAt:now,lastRefundOperationId:opId,
    ...(next?{refund:next}:{}),...(originalId?{correctionOfMovementId:originalId}:{}),...extra});
  if(!cancel && !next) {
    const value={type:'withdrawal',amountCents:1000,status:'active',personId:'person',description:'DEMO devolución',occurredAt:income.occurredAt,
      correctionOfMovementId:originalId??null,correctedByMovementId:null,cancellationReason:null,correctionReason:null};
    b.set(doc(s,p(`auditEvents/movement-created-${id}`)),{action:'movement.created',entityType:'movement',entityId:id,actorUid:actor,createdAt:now,before:null,after:value});
  }
  const refundedMonths={...balance?.refundedMonths};
  if(!omitRow)for(const month of all){const value=(refundedMonths[month]??0)-at(old,month)+at(next,month);if(value===0)delete refundedMonths[month];else refundedMonths[month]=value;}
  if(!omitBalance)b.set(doc(s,p(`allocationBalances/${source}`)),{...balance,lastAllocationId:balance?.lastAllocationId??null,
    allocatedCents:balance?.allocatedCents??0,refundedCents:(balance?.refundedCents??0)-total(old)+total(next),
    refundedAssignedCents:(balance?.refundedAssignedCents??0)-assigned(old)+assigned(next),refundedMonths,
    revision:(balance?.revision??0)+1,updatedBy:actor,updatedAt:now,lastAuditEventId:opId,lastRefundOperationId:opId,...extraBalance});
  if(!omitOperation)b.set(doc(s,p(`auditEvents/${opId}`)),{...op,action:`refund.${kind}`,entityType:'refund',entityId:opId,actorUid:actor,createdAt:now,
    before:{incomeId:source,movementId:originalId??null,amountCents:total(old)},after:{incomeId:source,movementId:cancel?null:id,amountCents:total(next)},...extraOperation});
  return {commit:()=>b.commit(),id,opId};
}
async function save(s,actor,opts){const t=await transition(s,actor,opts);await t.commit();return t;}
async function allocateAfterRefund(s,cents,ledgerPatch={}){
  const id=`income_${months[0]}`,before=(await getDoc(doc(s,p(`allocations/${id}`)))).data();
  const ledger=(await getDoc(doc(s,p('allocationBalances/income')))).data(),event=`assign-after-return-${++seq}`,now=serverTimestamp();
  const data={...before,amountCents:cents,revision:before.revision+1,updatedBy:'owner',updatedAt:now,lastAuditEventId:event};
  const summary=d=>({movementId:d.movementId,personId:d.personId,month:d.month,amountCents:d.amountCents,revision:d.revision});
  const b=writeBatch(s);b.set(doc(s,p(`allocations/${id}`)),data);
  b.set(doc(s,p('allocationBalances/income')),{...ledger,allocatedCents:ledger.allocatedCents-before.amountCents+cents,
    revision:ledger.revision+1,lastAllocationId:id,lastAuditEventId:event,updatedBy:'owner',updatedAt:now,...ledgerPatch});
  b.set(doc(s,p(`auditEvents/${event}`)),{action:'allocation.changed',entityType:'allocation',entityId:id,actorUid:'owner',createdAt:now,before:summary(before),after:summary(data)});
  return b.commit();
}
test('Refund combina cuotas parciales y crédito, conserva origen y bloquea dobles devoluciones',async()=>{
  const owner=db('owner'),result=await assertSucceeds(save(owner,'owner',{next:plan([[months[0],500],[months[1],1000]],1000)}));
  const balance=(await getDoc(doc(owner,p('allocationBalances/income')))).data();
  assert.equal(balance.allocatedCents-balance.refundedAssignedCents,6500);assert.equal(balance.refundedCents,2500);
  assert.equal((await getDoc(doc(db('member'),p(`allocations/income_${months[0]}`)))).data().amountCents-balance.refundedMonths[months[0]],1500);
  assert.equal((await getDoc(doc(owner,p('movements/income')))).data().amountCents,10000);
  await assertFails(updateDoc(doc(owner,p('movements/income')),{status:'cancelled',updatedAt:serverTimestamp(),cancelledAt:serverTimestamp(),cancelledBy:'owner',cancellationReason:'No omitir devoluciones'}));
  await assertFails(save(owner,'owner',{next:plan([],1001)}));
  await assertFails(deleteDoc(doc(owner,p(`auditEvents/${result.opId}`))));
  await assertFails(updateDoc(doc(owner,p(`auditEvents/${result.opId}`)),{amountCents:0}));
  await assertSucceeds(allocateAfterRefund(owner,2500));
  await assertFails(allocateAfterRefund(owner,499));
  await assertFails(allocateAfterRefund(owner,4000));
  await assertFails(allocateAfterRefund(owner,2600,{refundedCents:0,refundedAssignedCents:0,refundedMonths:{}}));
  await assertSucceeds(save(owner,'owner',{next:plan([],1000,'cash')}));
  assert.equal((await getDoc(doc(owner,p('allocationBalances/cash')))).data().lastAllocationId,null);
});
test('Refund exige permisos, importes válidos y todas las escrituras atómicas',async()=>{
  const owner=db('owner');
  await assertFails(save(db('member'),'member',{next:plan([],100)}));
  for(const patch of [{omitRow:true},{omitBalance:true},{omitOperation:true}])await assertFails(save(owner,'owner',{next:plan([[months[0],500]],500),...patch}));
  await assertFails(save(owner,'owner',{next:plan([],2001)}));
  await assertFails(save(owner,'owner',{next:plan([[months[0],2001]])}));
  await assertFails(save(owner,'owner',{next:plan([],100,'other')}));
  await assertFails(save(owner,'owner',{next:{...plan([],0),parts:{invalid:1}}}));
  await assertFails(save(owner,'owner',{next:{...plan([],0),parts:{[months[0]]:0}},extra:{amountCents:1}}));
  await assertFails(save(owner,'owner',{next:plan([[months[0],100]]),extraOperation:{changes:[String(months[0]),String(months[0])]}}));
  await assertFails(save(owner,'owner',{next:plan([],100),extraBalance:{refundedMonths:{[months[0]]:100}}}));
  await assertFails(save(owner,'owner',{next:plan([],100),extraOperation:{assignedCents:100}}));
  await assertFails(save(owner,'owner',{next:plan([],100),extra:{occurredAt:Timestamp.fromMillis(0)}}));
  await assertFails(save(owner,'owner',{next:plan([...months.map(m=>[m,1]),[24320,1]])}));
  await assertFails(save(owner,'owner',{next:plan([],100),extra:{amountCents:101}}));
  await assertFails(getDoc(doc(db('outsider'),p('refundOperations/absent'))));
});
test('Refund de cuatro meses por admin: corregir y anular restauran conjuntamente y conservan historia',async()=>{
  const admin=db('admin'),first=await assertSucceeds(save(admin,'admin',{next:plan(months.map((m,i)=>[m,300+i*100]),500)}));
  const second=await assertSucceeds(save(admin,'admin',{originalId:first.id,next:plan(months.map(m=>[m,500]),500)}));
  let balance=(await getDoc(doc(admin,p('allocationBalances/income')))).data();
  assert.equal(balance.allocatedCents-balance.refundedAssignedCents,6000);assert.equal(balance.refundedCents,2500);
  assert.equal((await getDoc(doc(admin,p(`movements/${first.id}`)))).data().status,'corrected');
  await assertSucceeds(save(admin,'admin',{originalId:second.id,cancel:true}));
  balance=(await getDoc(doc(admin,p('allocationBalances/income')))).data();
  assert.equal(balance.allocatedCents,8000);assert.equal(balance.refundedCents,0);assert.equal(balance.refundedAssignedCents,0);
  for(const m of months)assert.equal((await getDoc(doc(admin,p(`allocations/income_${m}`)))).data().amountCents,2000);
  await assertFails(save(admin,'admin',{originalId:second.id,cancel:true}));
  // Converting a refund to an ordinary withdrawal also restores its quota effects.
  const third=await save(admin,'admin',{next:plan([[months[0],500]],500)});
  await assertSucceeds(save(admin,'admin',{originalId:third.id,next:null}));
  assert.equal((await getDoc(doc(admin,p('allocationBalances/income')))).data().refundedCents,0);
});
test('Refund concurrentes no duplican crédito ni devuelven dos veces una cuota',async()=>{
  for(const value of [plan([],1500),plan([[months[0],1500]])]){
    const one=await transition(db('owner'),'owner',{next:value}),two=await transition(db('admin'),'admin',{next:value});
    const result=await Promise.allSettled([one.commit(),two.commit()]);
    assert.equal(result.filter(r=>r.status==='fulfilled').length,1);
    const winner=result[0].status==='fulfilled'?one:two;
    await save(db('owner'),'owner',{originalId:winner.id,cancel:true});
  }
});
