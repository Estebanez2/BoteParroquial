// Schema migration, not DEMO seeding. Default is read-only; --apply writes reciprocal links only.
const path=require('node:path');
const {createHash}=require('node:crypto');
const cli=process.env.FIREBASE_TOOLS_LIB || path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount}=require(path.join(cli,'auth'));
const {requireAuth}=require(path.join(cli,'requireAuth'));
const {Client}=require(path.join(cli,'apiv2'));
const project='boteparroquial',root=`projects/${project}/databases/(default)/documents`;
const hidden=()=>({skipLog:{reqBody:true,resBody:true}});
async function main(){
  await requireAuth({project,...getGlobalDefaultAccount(),nonInteractive:true});
  const api=new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  const query=async(parent,id)=>(await api.post(`${parent}:runQuery`,{structuredQuery:{from:[{collectionId:id}]}},hidden())).body.filter(row=>row.document).map(row=>row.document);
  const groups=await query(root,'groups'),plans=[],problems=[],examined=[];
  for(const group of groups){
    const [members,persons]=await Promise.all([query(group.name,'members'),query(group.name,'persons')]);
    examined.push({groupId:group.name.split('/').at(-1),members:members.length,persons:persons.length,claimed:members.filter(m=>m.fields.personId?.stringValue).length});
    const byId=new Map(persons.map(p=>[p.name.split('/').at(-1),p])),claimed=new Map();
    for(const member of members){
      const id=member.fields.personId?.stringValue;
      if(!id)continue;
      const uid=member.name.split('/').at(-1),person=byId.get(id);
      if(!person || claimed.has(id) || member.fields.uid?.stringValue!==uid){problems.push({groupId:group.name.split('/').at(-1),personId:id,reason:'Missing person, invalid UID or duplicate membership claim'});continue;}
      claimed.set(id,uid);
      const existing=person.fields.linkedUid;
      if(existing?.stringValue===uid)continue;
      if(existing?.stringValue){problems.push({personId:id,reason:'Conflicting reciprocal UID'});continue;}
      plans.push({groupId:group.name.split('/').at(-1),personId:id,uid,person,member});
    }
    for(const person of persons){
      const linked=person.fields.linkedUid?.stringValue,id=person.name.split('/').at(-1);
      if(linked && claimed.get(id)!==linked)problems.push({groupId:group.name.split('/').at(-1),personId:id,reason:'Reciprocal UID without matching membership'});
    }
  }
  if(problems.length){console.log(JSON.stringify({applied:false,conflicts:problems}));throw new Error('Resolver conflictos explícitamente antes de migrar; no se escribió nada.');}
  if(process.argv.includes('--apply') && plans.length){
    if(plans.length>150)throw new Error('Plan demasiado grande para esta migración atómica; dividir de forma revisada.');
    const writes=[];
    const str=value=>({stringValue:value}),map=fields=>({mapValue:{fields}});
    for(const item of plans){
      const id='link-backfill-v1-'+createHash('sha256').update(item.person.name).digest('hex').slice(0,20);
      writes.push({update:{name:item.person.name,fields:{linkedUid:str(item.uid),lastAuditEventId:str(id)}},
        updateMask:{fieldPaths:['linkedUid','lastAuditEventId']},currentDocument:{updateTime:item.person.updateTime}});
      // Verify the source snapshot in the same commit without changing its values.
      writes.push({update:{name:item.member.name,fields:{personId:str(item.personId)}},updateMask:{fieldPaths:['personId']},currentDocument:{updateTime:item.member.updateTime}});
      writes.push({update:{name:`${root}/groups/${item.groupId}/auditEvents/${id}`,fields:{
        action:str('person.linkBackfilled'),entityType:str('person'),entityId:str(item.personId),actorUid:str('system:backfill-person-links'),
        before:map({personId:str(item.personId),linkedUid:{nullValue:null}}),after:map({personId:str(item.personId),linkedUid:str(item.uid)})}},
        currentDocument:{exists:false},updateTransforms:[{fieldPath:'createdAt',setToServerValue:'REQUEST_TIME'}]});
    }
    await api.post(`${root}:commit`,{writes},hidden());
  }
  console.log(JSON.stringify({project,groups:groups.length,examined,applied:process.argv.includes('--apply'),links:plans.map(({groupId,personId,uid})=>({groupId,personId,uid})),
    pendingLinks:plans.length,conflicts:0,note:'No roles, person activity, names, money or photos changed.'}));
  if(process.argv.includes('--verify') && plans.length)process.exitCode=1;
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
