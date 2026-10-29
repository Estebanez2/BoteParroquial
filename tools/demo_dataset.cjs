// TEST fixture. No network, service credentials or Google accounts.
const {randomBytes}=require('node:crypto');
const OWNER='JDQpjp5XtFTDOoVgK5Rbc9EGUHB2';
const date=(month=1,day=1)=>new Date(Date.UTC(2026,month-1,day,9)).toISOString();
const ordinal=month=>2026*12+month-1;
const names=['Alejandro Estebanez Moreno','Marta García López','Luis Fernández Gil','Carmen Ruiz Sánchez','Pablo Martín Díaz','Lucía Torres Pérez','Javier Romero','Ana Moreno','Miguel Santos','Elena Castro','Diego López','Sara Molina'];
function buildDemo(){
  const documents=[],groups=[];
  const add=(path,data)=>{documents.push({path,data});return data;};
  for(const [index,count] of [[0,12],[1,8]]){
    const id=index===0?'demo-comunidad-20261020':'demo-jovenes-20261020';
    const name=index===0?'[DEMO] Comunidad San José':'[DEMO] Jóvenes y proyectos';
    const root=`groups/${id}`,created=date(),monthFee=m=>index===0?(m>=11?3000:m>=8?2500:2000):(m>=7?1500:1000);
    const persons=[],movements=[],allocations=[],periods=[],rules=[];
    const audit=(eventId,action,entityType,entityId,before,after,at=created,extra={})=>add(`${root}/auditEvents/${eventId}`,{action,entityType,entityId,actorUid:OWNER,createdAt:at,before,after,...extra});
    add(root,{name,description:'DEMO: datos ficticios para probar caja, cuotas, devoluciones, permisos y exportaciones. Se pueden modificar.',currency:'EUR',timeZone:'Europe/Madrid',isActive:true,createdBy:OWNER,updatedBy:OWNER,createdAt:created,updatedAt:created,lastAuditEventId:'created'});
    add(`${root}/members/${OWNER}`,{uid:OWNER,displayName:names[0],role:'owner',status:'active',personId:'owner',joinedAt:created,updatedAt:created});
    add(`${root}/members/${OWNER}/notificationPreferences/reminders`,{quotaPushEnabled:false,updatedAt:created});
    for(const category of ['informational','economic'])add(`${root}/members/${OWNER}/notificationPreferences/${category}`,{pushEnabled:false,updatedAt:created});
    audit('created','group.created','group',id,null,{name,description:'DEMO: datos ficticios para pruebas.'});
    for(const m of [1,index===0?8:7,...(index===0?[11]:[])]){
      const rule={id:String(ordinal(m)),effectiveFromMonth:ordinal(m),monthlyFeeCents:monthFee(m),revision:1};rules.push(rule);
      const eventId=`demo-quota-${m}`,summary={effectiveFromMonth:rule.effectiveFromMonth,monthlyFeeCents:rule.monthlyFeeCents,revision:1};
      add(`${root}/quotaRules/${rule.id}`,{...summary,createdBy:OWNER,updatedBy:OWNER,createdAt:created,updatedAt:created,lastAuditEventId:eventId});
      add(`${root}/quotaRules/${rule.id}/versions/${eventId}`,{...summary,actorUid:OWNER,createdAt:created});
      audit(eventId,'quota.changed','quotaRule',rule.id,null,summary);
    }
    add(`${root}/quotaSettings/current`,{firstMonth:ordinal(1),createdBy:OWNER,createdAt:created});
    for(let i=0;i<count;i++){
      const pid=i===0?'owner':`person-${String(i).padStart(2,'0')}`,first=i===8?3:1,last=i===6?6:null;
      const person={id:pid,displayName:`${i===0?'':'[DEMO] '}${names[i]}`,notes:`DEMO: ${i===1?'atrasos de septiembre/octubre':i===2?'pago parcial del mes actual':i===3?'sobrepago manual':i===4?'cuotas pendientes desde julio':i===5?'crédito sin asignar':i===6?'inactiva desde junio':'aportaciones de ejemplo'}.`,isActive:last===null,linkedUid:i===0?OWNER:null,lastParticipationPeriodId:`period-${pid}`,createdBy:OWNER,updatedBy:OWNER,createdAt:created,updatedAt:created,historyGuardVersion:1};
      persons.push(person);
      const period={id:`period-${pid}`,personId:pid,firstMonth:ordinal(first),lastMonthInclusive:last===null?null:ordinal(last)};periods.push(period);
      add(`${root}/participationPeriods/${period.id}`,{personId:pid,firstMonth:period.firstMonth,lastMonthInclusive:period.lastMonthInclusive,createdBy:OWNER,updatedBy:OWNER,createdAt:created,updatedAt:created,lastAuditEventId:`demo-period-${pid}`});
      audit(`demo-period-${pid}`,'participation.started','participationPeriod',period.id,null,{personId:pid,firstMonth:period.firstMonth,lastMonthInclusive:period.lastMonthInclusive});
    }
    function movement(mid,type,amount,month,personId=null,extra={}){
      const occurredAt=date(month,month===10?18:6),stamp=date(month,month===10?19:7);
      const value={id:mid,type,amountCents:amount,personId,description:`DEMO: ${type==='income'?'aportación':'material y actividades'} ${month}/2026`,occurredAt,status:'active',createdBy:OWNER,createdAt:stamp,updatedAt:stamp,...extra};
      movements.push(value);return value;
    }
    function allocation(source,month,amount){
      const person=persons.find(p=>p.id===source.personId),aid=`${source.id}_${ordinal(month)}`;
      const value={id:aid,movementId:source.id,personId:source.personId,month:ordinal(month),amountCents:amount,revision:1,participationPeriodId:person.lastParticipationPeriodId,createdBy:OWNER,updatedBy:OWNER,createdAt:source.createdAt,updatedAt:source.createdAt,lastAuditEventId:`demo-allocation-${aid}`};
      allocations.push(value);
      const summary={movementId:source.id,personId:source.personId,month:value.month,amountCents:amount,revision:1};
      audit(value.lastAuditEventId,'allocation.changed','allocation',aid,null,summary,source.createdAt);
    }
    for(let i=0;i<count;i++){
      const person=persons[i],period=periods[i];
      for(let m=period.firstMonth%12+1;m<=(i===6?6:10);m++){
        if(i===1&&m>=9||i===4&&m>=7)continue;
        const amount=i===2&&m===10?monthFee(m)/2:i%4===3&&m===10?monthFee(m)+500:monthFee(m);
        const source=movement(`income-${person.id}-${m}`,'income',amount,m,person.id);allocation(source,m,amount);
      }
    }
    const advance=movement('advance-owner','income',10000,10,'owner',{description:'DEMO: pago adelantado de noviembre/diciembre y crédito libre'});
    allocation(advance,11,monthFee(11));allocation(advance,12,monthFee(12));
    movement('credit-person-05','income',3500,10,'person-05',{description:'DEMO: ingreso sin repartir, no paga cuotas todavía'});
    const origin=movement('refund-origin','income',10000,5,'person-03',{description:'DEMO: origen de devolución con cuatro meses y crédito'});
    for(const m of [2,3,4,5])allocation(origin,m,2000);
    function refund(mid,source,parts,free=0,extra={}){
      const plan={incomeId:source.id,unallocatedCents:free,parts:Object.fromEntries(parts.map(([m,c])=>[ordinal(m),c]))};
      return movement(mid,'withdrawal',free+parts.reduce((a,p)=>a+p[1],0),10,source.personId,{description:'DEMO: devolución seleccionada de cuotas y crédito',refund:plan,lastRefundOperationId:`refund-${mid}`,...extra});
    }
    refund('refund-four-months',origin,[[2,250],[3,250],[4,250],[5,250]],500);
    refund('refund-advance',advance,[[11,500]],500);
    refund('refund-cancelled',origin,[[2,100]],0,{status:'cancelled',cancelledBy:OWNER,cancelledAt:date(10,19),cancellationReason:'DEMO: devolución anulada, pagos restaurados'});
    refund('refund-corrected',origin,[[3,200]],0,{status:'corrected',correctedBy:OWNER,correctedAt:date(10,19),correctionReason:'DEMO: ajustar devolución',correctedByMovementId:'refund-replacement'});
    refund('refund-replacement',origin,[[3,100]],0,{correctionOfMovementId:'refund-corrected'});
    for(let m=1;m<=10;m++)for(let n=0;n<4;n++)movement(`expense-${m}-${n}`,'withdrawal',350+m*43+n*117,m,null);
    movement('cancelled-income','income',9999,9,'person-02',{status:'cancelled',cancelledBy:OWNER,cancelledAt:date(9,8),cancellationReason:'DEMO: duplicado anulado'});
    movement('corrected-expense','withdrawal',1200,10,null,{status:'corrected',correctedBy:OWNER,correctedAt:date(10,19),correctionReason:'DEMO: corregir importe',correctedByMovementId:'replacement-expense'});
    movement('replacement-expense','withdrawal',900,10,null,{correctionOfMovementId:'corrected-expense'});
    for(const person of persons){
      const first=movements.find(m=>m.personId===person.id);if(first)person.firstMovementId=first.id;
      const {id:pid,...data}=person;add(`${root}/persons/${pid}`,data);
      audit(`demo-person-${pid}`,'person.created','person',pid,null,{displayName:person.displayName,notes:person.notes,isActive:person.isActive});
    }
    for(const value of allocations){const {id:aid,...data}=value;add(`${root}/allocations/${aid}`,data);}
    const summary=m=>({type:m.type,amountCents:m.amountCents,personId:m.personId,occurredAt:m.occurredAt,description:m.description,status:m.status,correctionOfMovementId:m.correctionOfMovementId??null,correctedByMovementId:m.correctedByMovementId??null,cancellationReason:m.cancellationReason??null,correctionReason:m.correctionReason??null});
    for(const value of movements){
      const {id:mid,...data}=value;add(`${root}/movements/${mid}`,data);
      if(value.refund){
        const assigned=Object.values(value.refund.parts).reduce((a,b)=>a+b,0),op=`refund-${mid}`;
        audit(op,'refund.create','refund',op,{incomeId:value.refund.incomeId,movementId:null,amountCents:0},{incomeId:value.refund.incomeId,movementId:mid,amountCents:value.amountCents},value.createdAt,{kind:'create',incomeId:value.refund.incomeId,originalMovementId:null,targetMovementId:mid,previousAmountCents:0,amountCents:value.amountCents,previousAssignedCents:0,assignedCents:assigned,changes:Object.keys(value.refund.parts),previousRefund:null,refund:value.refund});
      }else audit(`movement-created-${mid}`,'movement.created','movement',mid,null,{...summary(value),status:'active',correctedByMovementId:null,cancellationReason:null,correctionReason:null},value.createdAt);
      if(value.status!=='active')audit(`movement-${value.status}-${mid}`,`movement.${value.status}`,'movement',mid,{...summary(value),status:'active',correctedByMovementId:null,cancellationReason:null,correctionReason:null},summary(value),value.updatedAt);
    }
    for(const source of movements.filter(m=>m.type==='income'&&m.status==='active')){
      const rows=allocations.filter(a=>a.movementId===source.id),refunds=movements.filter(m=>m.refund?.incomeId===source.id&&m.status==='active');
      if(!rows.length&&!refunds.length)continue;
      const refundedMonths={};for(const r of refunds)for(const [m,c]of Object.entries(r.refund.parts))refundedMonths[m]=(refundedMonths[m]??0)+c;
      add(`${root}/allocationBalances/${source.id}`,{allocatedCents:rows.reduce((n,a)=>n+a.amountCents,0),revision:rows.length+refunds.length,lastAllocationId:rows.at(-1)?.id??null,lastAuditEventId:refunds.at(-1)?.lastRefundOperationId??rows.at(-1)?.lastAuditEventId,updatedBy:OWNER,updatedAt:date(10,19),...(refunds.length?{refundedCents:refunds.reduce((n,r)=>n+r.amountCents,0),refundedAssignedCents:Object.values(refundedMonths).reduce((a,b)=>a+b,0),refundedMonths,lastRefundOperationId:refunds.at(-1).lastRefundOperationId}:{})});
    }
    // Hidden trash candidates have no periods, movements, allocation or account link.
    for(const [pid,at]of [['trash-restorable',date(10,19)],['trash-expired',date(10,1)]]){
      const displayName=`[DEMO] ${pid==='trash-restorable'?'Restaurable diez días':'Papelera vencida'}`;
      add(`${root}/persons/${pid}`,{displayName,notes:'DEMO: solo para probar papelera, sin historia económica.',isActive:false,historyGuardVersion:1,createdBy:OWNER,updatedBy:OWNER,createdAt:created,updatedAt:at,trashedAt:at,trashedBy:OWNER,trashedWasActive:true});
      audit(`demo-trash-${pid}`,'person.trashed','person',pid,{displayName,notes:null,isActive:true},{displayName,notes:null,isActive:false},at);
    }
    const secret=randomBytes(24).toString('base64url');
    if(secret.length!==32)throw new Error('invalid_demo_invitation');
    add(`${root}/invitationSettings/current`,{code:secret,enabled:true,requiresApproval:index===0,updatedBy:OWNER,updatedAt:created,lastAuditEventId:'demo-invitation'});
    add(`${root}/invitations/${secret}`,{groupName:name,currency:'EUR',requiresApproval:index===0,createdAt:created,updatedAt:created});
    audit('demo-invitation','invitation.changed','invitation','current',null,{enabled:true,requiresApproval:index===0,regenerated:true});
    const valid=movements.filter(m=>m.status==='active'),income=valid.filter(m=>m.type==='income').reduce((n,m)=>n+m.amountCents,0),withdrawal=valid.filter(m=>m.type==='withdrawal').reduce((n,m)=>n+m.amountCents,0);
    groups.push({id,name,persons:count,activePersons:count-1,trash:2,movements:movements.length,incomeCents:income,withdrawalCents:withdrawal,balanceCents:income-withdrawal,allocations:allocations.length,invitationRequiresApproval:index===0});
  }
  add(`users/${OWNER}`,{displayName:names[0],email:'ale.manu.cristi@gmail.com',photoUrl:null,createdAt:date(),updatedAt:date(),lastSignInAt:date()});
  return {format:'boteparroquial.demo/v1',createdFor:'2026-10-20',owner:OWNER,groups,documents};
}
module.exports={buildDemo,OWNER};
if(require.main===module){const fs=require('node:fs');const demo=buildDemo();fs.writeFileSync('.dart_tool/demo-dataset.json',JSON.stringify(demo));console.log(JSON.stringify({groups:demo.groups,documents:demo.documents.length}));}
