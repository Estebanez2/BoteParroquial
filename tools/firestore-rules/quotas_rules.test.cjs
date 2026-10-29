const {before,beforeEach,after,test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc,updateDoc,deleteDoc,writeBatch,serverTimestamp,Timestamp}=require('firebase/firestore');
let env,seq=0;
const p=s=>`groups/a/${s}`, db=uid=>env.authenticatedContext(uid).firestore();
function civilMonth(date,zone='Europe/Madrid') {
  const parts=new Intl.DateTimeFormat('en',{timeZone:zone,year:'numeric',month:'2-digit'}).formatToParts(date);
  return Number(parts.find(p=>p.type==='year').value)*12+Number(parts.find(p=>p.type==='month').value)-1;
}
const nowMonth=()=>civilMonth(new Date());
before(async()=>{
  const rules=readFileSync(join(__dirname,'../../firestore.rules'),'utf8');
  // Only this test environment adds a read-only probe for the pure calendar helper.
  const tested=rules.replace('    // The uid filter',`    match /calendarChecks/{id} {
      allow read: if request.auth != null && billingMonthAt(resource.data.zone,resource.data.instant) == resource.data.expectedMonth;
    }
    // The uid filter`);
  env=await initializeTestEnvironment({projectId:'demo-boteparroquial-quotas',firestore:{rules:tested}});
});
after(async()=>{if(env)await env.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async ctx=>{
    const store=ctx.firestore(),b=writeBatch(store),now=Timestamp.now();
    b.set(doc(store,'groups/a'),{name:'DEMO Cuotas',isActive:true,timeZone:'Europe/Madrid'});
    b.set(doc(store,'groups/b'),{isActive:true,timeZone:'Europe/Madrid'});
    for(const[uid,role]of[['owner','owner'],['admin','admin'],['member','member']]){
      b.set(doc(store,p(`members/${uid}`)),{uid,displayName:uid,role,status:'active',personId:uid==='member'?null:`${uid}-person`,joinedAt:now,updatedAt:now});
    }
    for(const[id,uid]of[['owner-person','owner'],['admin-person','admin'],['one',null]]){
      b.set(doc(store,p(`persons/${id}`)),{displayName:id,isActive:true,linkedUid:uid,createdAt:now,updatedAt:now,createdBy:'owner',updatedBy:'owner'});
    }
    await b.commit();
  });
});
const summary=d=>({effectiveFromMonth:d.effectiveFromMonth,monthlyFeeCents:d.monthlyFeeCents,revision:d.revision});
async function createWithPeriod(store,actor,month,{omitPeriod=false,omitAudit=false,omitPerson=false,extra={}}={}) {
  const personId=`new-${++seq}`,periodId=`initial-${personId}`,auditId=`person-created-${personId}`,now=serverTimestamp(),b=writeBatch(store);
  if(!omitPerson)b.set(doc(store,p(`persons/${personId}`)),{displayName:'DEMO nueva persona',notes:null,isActive:true,
    createdBy:actor,updatedBy:actor,createdAt:now,updatedAt:now,lastParticipationPeriodId:periodId,lastAuditEventId:auditId,...extra});
  if(!omitPeriod)b.set(doc(store,p(`participationPeriods/${periodId}`)),{personId,firstMonth:month,lastMonthInclusive:null,
    createdBy:actor,updatedBy:actor,createdAt:now,updatedAt:now,lastAuditEventId:auditId});
  if(!omitAudit)b.set(doc(store,p(`auditEvents/${auditId}`)),{action:'person.createdWithParticipation',entityType:'person',entityId:personId,
    actorUid:actor,createdAt:now,before:null,after:{displayName:'DEMO nueva persona',notes:null,periodId,firstMonth:month,isActive:true}});
  await b.commit();return{personId,periodId,auditId};
}
test('Alta con primer mes explícito crea persona, etapa y auditoría juntas',async()=>{
  for(const actor of ['owner','admin']){
    const store=db(actor),created=await assertSucceeds(createWithPeriod(store,actor,nowMonth()-2));
    const person=(await getDoc(doc(store,p(`persons/${created.personId}`)))).data();
    assert.equal(person.lastParticipationPeriodId,created.periodId);
    assert.equal((await getDoc(doc(store,p(`participationPeriods/${created.periodId}`)))).data().firstMonth,nowMonth()-2);
    await assertFails(deleteDoc(doc(store,p(`persons/${created.personId}`))));
    await assertFails(updateDoc(doc(store,p(`auditEvents/${created.auditId}`)),{after:{firstMonth:0}}));
  }
});
test('Alta mensual rechaza meses futuros, miembros, vínculos falsos y omitir una parte',async()=>{
  const store=db('owner');
  await assertFails(createWithPeriod(store,'owner',nowMonth()+1));
  await assertFails(createWithPeriod(store,'owner',nowMonth(),{omitPeriod:true}));
  await assertFails(createWithPeriod(store,'owner',nowMonth(),{omitAudit:true}));
  await assertFails(createWithPeriod(store,'owner',nowMonth(),{omitPerson:true}));
  await assertFails(createWithPeriod(store,'owner',nowMonth(),{extra:{linkedUid:'member'}}));
  await assertFails(createWithPeriod(db('member'),'member',nowMonth()));
  await assertFails(createWithPeriod(db('outsider'),'outsider',nowMonth()));
});
async function saveRule(store,actor,month,cents,{omitVersion=false,omitAudit=false,extra={}}={}){
  const root=doc(store,p(`quotaRules/${month}`)),config=doc(store,p('quotaSettings/current'));
  const old=(await getDoc(root)).data(),settings=(await getDoc(config)).data();
  const id=`quota-${++seq}`,now=serverTimestamp(),b=writeBatch(store);
  const data={effectiveFromMonth:month,monthlyFeeCents:cents,revision:(old?.revision??0)+1,createdBy:old?.createdBy??actor,createdAt:old?.createdAt??now,updatedBy:actor,updatedAt:now,lastAuditEventId:id,...extra};
  b.set(root,data);
  if(!settings)b.set(config,{firstMonth:month,createdBy:actor,createdAt:now});
  if(!omitVersion)b.set(doc(store,p(`quotaRules/${month}/versions/${id}`)),{...summary(data),actorUid:actor,createdAt:now});
  if(!omitAudit)b.set(doc(store,p(`auditEvents/${id}`)),{action:'quota.changed',entityType:'quotaRule',entityId:String(month),actorUid:actor,createdAt:now,before:old?summary(old):null,after:summary(data)});
  return b.commit();
}
async function start(store,actor,pid,month,{omitPerson=false,omitAudit=false}={}){
  const root=doc(store,p(`persons/${pid}`)),person=(await getDoc(root)).data();
  const id=`period-${++seq}`,audit=`start-${seq}`,now=serverTimestamp(),b=writeBatch(store);
  b.set(doc(store,p(`participationPeriods/${id}`)),{personId:pid,firstMonth:month,lastMonthInclusive:null,createdBy:actor,createdAt:now,updatedBy:actor,updatedAt:now,lastAuditEventId:audit});
  if(!omitPerson)b.update(root,{isActive:true,lastParticipationPeriodId:id,updatedBy:actor,updatedAt:now,lastAuditEventId:audit});
  if(!omitAudit)b.set(doc(store,p(`auditEvents/${audit}`)),{action:'participation.started',entityType:'person',entityId:pid,actorUid:actor,createdAt:now,before:{periodId:person.lastParticipationPeriodId??null,isActive:person.isActive},after:{periodId:id,firstMonth:month,isActive:true}});
  await b.commit();return id;
}
async function close(store,actor,pid,month,{omitPeriod=false,omitDemotion=false}={}){
  const root=doc(store,p(`persons/${pid}`)),person=(await getDoc(root)).data();
  const ref=doc(store,p(`participationPeriods/${person.lastParticipationPeriodId}`)),period=(await getDoc(ref)).data();
  const member=person.linkedUid?(await getDoc(doc(store,p(`members/${person.linkedUid}`)))).data():null;
  const id=`close-${++seq}`,now=serverTimestamp(),b=writeBatch(store),role=member?.role??null;
  b.update(root,{isActive:false,updatedBy:actor,updatedAt:now,lastAuditEventId:id});
  if(!omitPeriod)b.update(ref,{lastMonthInclusive:month,updatedBy:actor,updatedAt:now,lastAuditEventId:id});
  if(role==='admin'&&!omitDemotion)b.update(doc(store,p(`members/${person.linkedUid}`)),{role:'member',updatedAt:now,lastAuditEventId:id});
  const common={linkedUid:person.linkedUid??null,periodId:person.lastParticipationPeriodId,firstMonth:period.firstMonth};
  b.set(doc(store,p(`auditEvents/${id}`)),{action:'person.inactivated',entityType:'person',entityId:pid,actorUid:actor,createdAt:now,
    before:{...common,isActive:true,role,lastMonthInclusive:null},after:{...common,isActive:false,role:role==='admin'?'member':role,lastMonthInclusive:month}});
  return b.commit();
}
test('Cuotas: primera regla explícita, cambios futuros versionados, cero, permisos y conservación histórica',async()=>{
  const owner=db('owner'),admin=db('admin'),current=nowMonth();
  await assertFails(saveRule(db('member'),'member',current-2,2000));
  await assertFails(saveRule(owner,'owner',current-2,2000,{omitVersion:true}));
  await assertFails(saveRule(owner,'owner',current-2,2000,{omitAudit:true}));
  await assertSucceeds(saveRule(owner,'owner',current-2,2050));
  await assertFails(saveRule(owner,'owner',current-2,2500));
  await assertFails(saveRule(owner,'owner',current,2500));
  await assertFails(saveRule(owner,'owner',current+1,-1));
  await assertFails(saveRule(owner,'owner',current+1,20.5));
  await assertSucceeds(saveRule(admin,'admin',current+1,2500));
  const original=(await getDoc(doc(owner,p(`quotaRules/${current+1}`)))).data();
  await assertSucceeds(saveRule(owner,'owner',current+1,0));
  const updated=(await getDoc(doc(owner,p(`quotaRules/${current+1}`)))).data();
  assert.equal(updated.monthlyFeeCents,0);assert.equal(updated.revision,2);
  const version=doc(owner,p(`quotaRules/${current+1}/versions/${original.lastAuditEventId}`));
  assert.equal((await getDoc(version)).data().monthlyFeeCents,2500);
  await assertFails(updateDoc(version,{monthlyFeeCents:1}));await assertFails(deleteDoc(version));
  await assertFails(deleteDoc(doc(owner,p(`quotaRules/${current-2}`))));
  await assertFails(updateDoc(doc(owner,p('quotaSettings/current')),{firstMonth:current}));
  await assertFails(getDoc(doc(db('stranger'),p(`quotaRules/${current-2}`))));
  await assertSucceeds(getDoc(doc(db('member'),p(`quotaRules/${current-2}`))));
  const results=await Promise.allSettled([3000,3500].map(cents=>saveRule(owner,'owner',current+2,cents)));
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
});
test('Periodos: inicio explícito, baja inclusiva, reserva de historia y reincorporación sin solapamientos',async()=>{
  const owner=db('owner'),current=nowMonth();
  await assertFails(start(db('member'),'member','one',current-3));
  await assertFails(start(owner,'owner','one',current-3,{omitPerson:true}));
  await assertFails(start(owner,'owner','one',current-3,{omitAudit:true}));
  await assertFails(start(owner,'owner','one',current+1));
  const initial=await assertSucceeds(start(owner,'owner','one',current-3));
  await assertFails(start(owner,'owner','one',current));
  await assertFails(close(owner,'owner','one',current-4));
  await assertFails(close(owner,'owner','one',current+1));
  await assertFails(close(owner,'owner','one',current-1,{omitPeriod:true}));
  await assertSucceeds(close(owner,'owner','one',current-1));
  await assertFails(updateDoc(doc(owner,p('persons/one')),{isActive:true,updatedAt:serverTimestamp(),updatedBy:'owner'}));
  await assertFails(start(owner,'owner','one',current-2));
  await assertSucceeds(start(owner,'owner','one',current-1));
  await assertSucceeds(close(owner,'owner','one',current-1));
  await assertSucceeds(start(owner,'owner','one',current));
  assert.equal((await getDoc(doc(owner,p(`participationPeriods/${initial}`)))).data().lastMonthInclusive,current-1);
  await assertFails(updateDoc(doc(owner,p(`participationPeriods/${initial}`)),{firstMonth:current-4,updatedBy:'owner',updatedAt:serverTimestamp()}));
  await assertFails(deleteDoc(doc(owner,p(`participationPeriods/${initial}`))));
  const results=await Promise.allSettled([current-2,current-1].map(m=>start(owner,'owner','owner-person',m)));
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
});
test('Baja con periodo degrada admin en el mismo commit y reactivación no devuelve su rol',async()=>{
  const owner=db('owner'),admin=db('admin'),current=nowMonth();
  await assertSucceeds(start(admin,'admin','admin-person',current-1));
  await assertFails(close(owner,'owner','admin-person',current,{omitDemotion:true}));
  await assertSucceeds(close(admin,'admin','admin-person',current-1));
  assert.equal((await getDoc(doc(owner,p('members/admin')))).data().role,'member');
  await assertFails(start(admin,'admin','admin-person',current));
  await assertSucceeds(start(owner,'owner','admin-person',current));
  assert.equal((await getDoc(doc(owner,p('members/admin')))).data().role,'member');
});
test('Calendario de servidor: límites de mes, DST y año en las seis zonas admitidas',async()=>{
  const cases=[['Europe/Madrid','2026-03-31T22:30:00Z'],['Europe/Madrid','2026-10-31T22:30:00Z'],['Europe/Madrid','2026-10-31T23:30:00Z'],
    ['Europe/London','2026-03-31T23:30:00Z'],['Europe/London','2026-10-31T23:30:00Z'],['Atlantic/Canary','2026-03-31T23:30:00Z'],
    ['America/New_York','2026-11-01T04:30:00Z'],['America/New_York','2026-01-01T04:30:00Z'],['America/New_York','2026-04-01T04:30:00Z'],
    ['America/Bogota','2026-01-01T04:30:00Z'],['America/Mexico_City','2026-01-01T05:30:00Z'],['America/Mexico_City','2026-01-01T06:30:00Z']];
  await env.withSecurityRulesDisabled(async ctx=>{
    const store=ctx.firestore(),b=writeBatch(store);
    cases.forEach(([zone,time],i)=>{const date=new Date(time);b.set(doc(store,`calendarChecks/${i}`),{zone,instant:Timestamp.fromDate(date),expectedMonth:civilMonth(date,zone)});});
    await b.commit();
  });
  for(let i=0;i<cases.length;i++)await assertSucceeds(getDoc(doc(db('member'),`calendarChecks/${i}`)));
});
