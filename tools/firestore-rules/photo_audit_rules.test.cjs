const {before,after,test}=require('node:test');
const {readFileSync}=require('node:fs'),{join}=require('node:path');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,getDocs,collection,deleteDoc,serverTimestamp}=require('firebase/firestore');
let env,seq=0;
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-boteparroquial-photo-audit',firestore:{rules:readFileSync(join(__dirname,'../../firestore.rules'),'utf8')}});await env.withSecurityRulesDisabled(async c=>{
  const s=c.firestore();await setDoc(doc(s,'groups/a'),{isActive:true});await setDoc(doc(s,'groups/a/persons/admin-person'),{isActive:true});
  for(const[uid,role]of[['owner','owner'],['admin','admin'],['peer','admin'],['member','member']])await setDoc(doc(s,`groups/a/members/${uid}`),{uid,role,status:'active',personId:role==='admin'?'admin-person':null});
});});
after(async()=>{if(env)await env.cleanup();});
function event(actor,targetId,operationId,phase='request'){return {action:phase==='request'?'photo.changeRequested':'photo.changeCompleted',entityType:'photo',entityId:targetId,actorUid:actor,createdAt:serverTimestamp(),before:{fingerprint:null},after:{operationId,mode:'upload',targetKind:'member',targetId,fingerprint:'a'.repeat(64)}};}
test('Auditoría de fotos respeta permisos de miembro/admin/owner y confirmación ligada',async()=>{
  for(const[actor,target,allowed]of[['member','member',true],['member','owner',false],['admin','member',true],['admin','peer',false],['owner','admin',true]]) {
    const s=env.authenticatedContext(actor).firestore(),id=(++seq).toString(16).padStart(32,'0'),data=event(actor,target,id);
    const request=doc(s,`groups/a/auditEvents/photo-request-${id}`),complete=doc(s,`groups/a/auditEvents/photo-complete-${id}`);
    if(!allowed){await assertFails(setDoc(request,data));continue;}
    await assertSucceeds(setDoc(request,data));await assertSucceeds(getDoc(request));
    const completed=event(actor,target,id,'complete');
    await assertFails(setDoc(complete,{...completed,after:{...completed.after,fingerprint:'b'.repeat(64)}}));
    await assertSucceeds(setDoc(complete,completed));await assertFails(deleteDoc(complete));
  }
  await assertFails(getDocs(collection(env.authenticatedContext('member').firestore(),'groups/a/auditEvents')));
});
