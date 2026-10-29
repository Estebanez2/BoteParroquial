// Create-only DEMO data. No money, roles in existing groups, deletion or push.
const fs=require('node:fs'),path=require('node:path');
const cli=path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount}=require(path.join(cli,'auth'));
const {requireAuth}=require(path.join(cli,'requireAuth'));
const {Client}=require(path.join(cli,'apiv2'));
const project='boteparroquial',uid='JDQpjp5XtFTDOoVgK5Rbc9EGUHB2';
const groupId='demo-notifications-20261020',guest='DEMO-notification-guest';
const root=`projects/${project}/databases/(default)/documents`;
function field(v){if(v===null)return{nullValue:null};if(typeof v==='boolean')return{booleanValue:v};if(typeof v==='object')return{mapValue:{fields:fields(v)}};return{stringValue:v};}
function fields(data){return Object.fromEntries(Object.entries(data).map(([k,v])=>[k,field(v)]));}
(async()=>{
  await requireAuth({project,...getGlobalDefaultAccount(),nonInteractive:true});
  const api=new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  await api.get(`${root}/users/${uid}`,{skipLog:{resBody:true}});
  const data={
    [`groups/${groupId}`]:{name:'[Prueba] Pipeline de avisos',description:'DEMO: validación técnica sin entrega push; el solicitante no es una cuenta real.',currency:'EUR',timeZone:'Europe/Madrid',isActive:true,createdBy:uid,updatedBy:uid,lastAuditEventId:'created'},
    [`groups/${groupId}/members/${uid}`]:{uid,displayName:'[Prueba] Cuenta de validación',role:'owner',status:'active',personId:null,lastAuditEventId:'created'},
    [`groups/${groupId}/members/${uid}/notificationPreferences/informative`]:{pushEnabled:false},
    [`groups/${groupId}/members/${uid}/notificationPreferences/economic`]:{pushEnabled:false},
    [`groups/${groupId}/members/${uid}/notificationPreferences/reminders`]:{quotaPushEnabled:false},
    [`groups/${groupId}/auditEvents/created`]:{action:'group.created',entityType:'group',entityId:groupId,actorUid:uid,before:null,after:{name:'[Prueba] Pipeline de avisos',currency:'EUR',timeZone:'Europe/Madrid'}},
    [`groups/${groupId}/joinRequests/${guest}`]:{uid:guest,displayName:'[Prueba] Solicitante DEMO sin cuenta real',code:'DEMO',status:'pending',reviewedBy:null,reviewedAt:null,lastAuditEventId:'demo-request'},
    [`groups/${groupId}/auditEvents/demo-request`]:{action:'join.requested',entityType:'joinRequest',entityId:guest,actorUid:guest,before:null,after:{uid:guest,displayName:'[Prueba] Solicitante DEMO sin cuenta real',status:'pending'}},
  };
  const writes=Object.entries(data).map(([p,v])=>{
    const timestamps=p.includes('/notificationPreferences/')?['updatedAt']
      :p.includes('/auditEvents/')?['createdAt']
      :p.endsWith(`/members/${uid}`)?['joinedAt','updatedAt']:['createdAt','updatedAt'];
    return {update:{name:`${root}/${p}`,fields:fields(v)},currentDocument:{exists:false},
      updateTransforms:timestamps.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))};
  });
  await api.post(`${root}:commit`,{writes},{skipLog:{reqBody:true,resBody:true}});
  const info={groupId,documentsCreated:writes.length,ownerUid:uid,guestIsFictitious:true,allPushDisabled:true,financialDocumentsCreated:0};
  fs.writeFileSync('.dart_tool/notification-demo.json',JSON.stringify(info,null,2),{flag:'wx'});
  console.log(JSON.stringify(info));
})().catch(()=>{console.error('No se creó la muestra: los documentos existentes no se sobrescriben.');process.exitCode=1;});
