const {before,after,beforeEach,test}=require('node:test');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,collection,getDoc,getDocs,setDoc,updateDoc,deleteDoc,writeBatch,runTransaction,serverTimestamp,Timestamp}=require('firebase/firestore');
let env;
const movement=(uid,patch={})=>({type:'income',amountCents:2050,status:'active',occurredAt:Timestamp.fromDate(new Date('2026-10-15T00:00:00Z')),
  description:'Prueba',personId:'p',createdBy:uid,createdAt:serverTimestamp(),updatedAt:serverTimestamp(),...patch});
const cancel=(uid,patch={})=>({status:'cancelled',updatedAt:serverTimestamp(),cancelledAt:serverTimestamp(),cancelledBy:uid,cancellationReason:'Duplicado',...patch});
const correct=(uid,id)=>({status:'corrected',updatedAt:serverTimestamp(),correctedAt:serverTimestamp(),correctedBy:uid,correctionReason:'Importe incorrecto',correctedByMovementId:id});
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-boteparroquial-movements',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context=>{
    const db=context.firestore();
    await setDoc(doc(db,'groups/a'),{isActive:true});
    await setDoc(doc(db,'groups/b'),{isActive:true});
    await setDoc(doc(db,'groups/a/persons/p'),{isActive:true});
    await setDoc(doc(db,'groups/a/persons/inactive'),{isActive:false});
    for(const [uid,role,status,personId] of [['owner','owner','active',null],['admin','admin','active','p'],['member','member','active',null],['inactive','owner','inactive',null]]) {
      await setDoc(doc(db,`groups/a/members/${uid}`),{uid,role,status,personId});
    }
  });
});
after(async()=>{if(env)await env.cleanup();});
test('Permisos, céntimos, autores, fechas y personas del mismo grupo',async()=>{
  const owner=env.authenticatedContext('owner').firestore();
  await assertSucceeds(setDoc(doc(owner,'groups/a/movements/income'),movement('owner')));
  await assertSucceeds(setDoc(doc(owner,'groups/a/movements/withdrawal'),movement('owner',{type:'withdrawal',personId:null,amountCents:6000,description:'Saldo negativo permitido'})));
  await assertSucceeds(setDoc(doc(owner,'groups/a/movements/late'),movement('owner',{personId:'inactive'})));
  await assertSucceeds(setDoc(doc(env.authenticatedContext('admin').firestore(),'groups/a/movements/admin'),movement('admin')));
  await assertSucceeds(getDocs(collection(env.authenticatedContext('member').firestore(),'groups/a/movements')));
  for(const db of [env.authenticatedContext('member').firestore(),env.authenticatedContext('inactive').firestore(),env.authenticatedContext('outsider').firestore(),env.unauthenticatedContext().firestore()]) {
    await assertFails(setDoc(doc(db,'groups/a/movements/forbidden'),movement('owner')));
  }
  await assertFails(getDocs(collection(env.authenticatedContext('outsider').firestore(),'groups/a/movements')));
  await assertFails(getDocs(collection(owner,'groups/b/movements')));
  for(const patch of [{amountCents:20.5},{amountCents:0},{amountCents:-100},{createdBy:'other'},{createdAt:Timestamp.fromMillis(1)},
    {personId:'missing'},{personId:null},{type:'withdrawal',description:'  '},{role:'owner'},{status:'cancelled'},{amountCents:100000000000000},
    {occurredAt:Timestamp.fromMillis(Date.now()+3*86400000)},
    {occurredAt:Timestamp.fromDate(new Date('2025-01-01T12:00:00Z'))}]) {
    await assertFails(setDoc(doc(owner,'groups/a/movements/invalid'),movement('owner',patch)));
  }
  await assertFails(updateDoc(doc(owner,'groups/a/movements/income'),{amountCents:100,updatedAt:serverTimestamp()}));
  await assertFails(deleteDoc(doc(owner,'groups/a/movements/income')));
});
test('Corrección atómica conserva original y evita sustitutos huérfanos o reutilizados',async()=>{
  const db=env.authenticatedContext('owner').firestore();
  const original=doc(db,'groups/a/movements/original'),replacement=doc(db,'groups/a/movements/replacement');
  await setDoc(original,movement('owner'));
  await assertFails(updateDoc(original,correct('owner','replacement')));
  await assertFails(setDoc(replacement,movement('owner',{amountCents:3000,correctionOfMovementId:'original'})));
  const batch=writeBatch(db);
  batch.update(original,correct('owner','replacement'));
  batch.set(replacement,movement('owner',{amountCents:3000,correctionOfMovementId:'original'}));
  await assertSucceeds(batch.commit());
  const originalData=(await getDoc(original)).data();
  if(originalData.amountCents!==2050||originalData.status!=='corrected')throw new Error('Original alterado');
  const rows=(await getDocs(collection(db,'groups/a/movements'))).docs.map(doc=>doc.data());
  const balance=rows.filter(m=>m.status==='active').reduce((sum,m)=>sum+(m.type==='income'?m.amountCents:-m.amountCents),0);
  if(balance!==3000)throw new Error('Doble contabilización');
  await assertFails(updateDoc(original,{status:'active',updatedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(db,'groups/a/movements/extra'),movement('owner',{correctionOfMovementId:'original'})));
  // A replacement may itself be corrected, preserving the entire chain.
  const chain=writeBatch(db);
  chain.update(replacement,correct('owner','third'));
  chain.set(doc(db,'groups/a/movements/third'),movement('owner',{amountCents:1000,correctionOfMovementId:'replacement'}));
  await assertSucceeds(chain.commit());
});
test('Anulación es terminal y exige motivo, autor y fecha',async()=>{
  const db=env.authenticatedContext('owner').firestore();
  const ref=doc(db,'groups/a/movements/m');
  await setDoc(ref,movement('owner'));
  await assertFails(updateDoc(ref,cancel('owner',{cancellationReason:' '})));
  await assertFails(updateDoc(ref,cancel('owner',{cancelledBy:'other'})));
  await assertSucceeds(updateDoc(ref,cancel('owner')));
  await assertFails(updateDoc(ref,{status:'active',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref,correct('owner','new')));
  await assertFails(deleteDoc(ref));
});
test('Dos operaciones concurrentes sobre un original solo producen un resultado',async()=>{
  const db=env.authenticatedContext('owner').firestore();
  const ref=doc(db,'groups/a/movements/race');
  await setDoc(ref,movement('owner'));
  const results=await Promise.allSettled(['one','two'].map(id=>runTransaction(db,async tx=>{
    const current=await tx.get(ref);
    if(current.data().status!=='active')throw new Error('Ya procesado');
    tx.update(ref,correct('owner',id));
    tx.set(doc(db,`groups/a/movements/${id}`),movement('owner',{correctionOfMovementId:'race'}));
  })));
  if(results.filter(r=>r.status==='fulfilled').length!==1)throw new Error('Se aceptaron dos correcciones');
  const rows=(await getDocs(collection(db,'groups/a/movements'))).docs;
  if(rows.length!==2)throw new Error('Sustitutos duplicados');
});
