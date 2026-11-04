const {test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {join}=require('node:path');
const {initializeTestEnvironment}=require('@firebase/rules-unit-testing');
const {createMockUserToken}=require('@firebase/util');
const {doc,setDoc}=require('firebase/firestore');
test('Lecturas REST de una copia con UID real de cliente, incluidas consultas y documentos ausentes',async()=>{
 const project='demo-boteparroquial-copies';
 const env=await initializeTestEnvironment({projectId:project,firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});
 try{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c=>{
   const db=c.firestore();
   await setDoc(doc(db,'users/alice'),{displayName:'DEMO'});
   await setDoc(doc(db,'groups/a'),{isActive:true,timeZone:'Europe/Madrid'});
   await setDoc(doc(db,'groups/a/members/alice'),{uid:'alice',status:'active',role:'owner'});
  });
  const root=`projects/${project}/databases/(default)/documents`;
  const token=createMockUserToken({sub:'alice',user_id:'alice'},project);
  const call=async(action,body)=>{
   const r=await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/${root}${action}`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify(body)});
   const value=await r.json();
   assert.equal(r.status,200,`${action}: ${JSON.stringify(value)}`);
   return value;
  };
  const from=(collection,desc=false)=>[{collectionId:collection,allDescendants:desc}];
  const filter=(field,value)=>({fieldFilter:{field:{fieldPath:field},op:'EQUAL',value:{stringValue:value}}});
  const membership=await call(':runQuery',{structuredQuery:{from:from('members',true),where:filter('uid','alice'),limit:1}});
  const time=membership.at(-1).readTime;
  await call(':runQuery',{readTime:time,structuredQuery:{from:from('members',true),where:filter('uid','alice'),orderBy:[{field:{fieldPath:'__name__'},direction:'ASCENDING'}],limit:200}});
  for(const path of ['users/alice','groups/a','groups/a/quotaSettings/current','groups/a/invitationSettings/current',...['reminders','economic','informative'].map(k=>`groups/a/members/alice/notificationPreferences/${k}`)]){
   await call(':batchGet',{documents:[`${root}/${path}`],readTime:time});
  }
  for(const [parent,collection]of [['users/alice','auditEvents'],...['persons','members','movements','quotaRules','participationPeriods','allocations','allocationBalances','auditEvents','joinRequests','notifications'].map(k=>['groups/a',k])]){
   await call(`/${parent}:runQuery`,{readTime:time,structuredQuery:{from:from(collection),orderBy:[{field:{fieldPath:'__name__'},direction:'ASCENDING'}],limit:collection==='notifications'?50:200,...(collection==='notifications'?{where:filter('recipientUid','alice')}:{} )}});
  }
 }finally{await env.cleanup();}
});
