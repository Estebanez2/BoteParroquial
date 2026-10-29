// Create-only DEMO fixtures for the linking screen; no Auth accounts or financial writes.
const path=require('node:path');
const cli=process.env.FIREBASE_TOOLS_LIB||path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount}=require(path.join(cli,'auth'));
const {requireAuth}=require(path.join(cli,'requireAuth'));
const {Client}=require(path.join(cli,'apiv2'));
const groupId='demo7-invitations-20261017',project='boteparroquial';
async function main(){
  await requireAuth({project,...getGlobalDefaultAccount(),nonInteractive:true});
  const api=new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'}),root=`projects/${project}/databases/(default)/documents/groups/${groupId}`;
  const hide=()=>({skipLog:{reqBody:true,resBody:true}});
  const group=(await api.get(root,hide())).body.fields,uid=group.createdBy.stringValue;
  const owner=(await api.get(`${root}/members/${uid}`,hide())).body.fields;
  if(group.isActive.booleanValue!==true||owner.role.stringValue!=='owner'||owner.status.stringValue!=='active')throw new Error('Se requiere grupo DEMO y owner activos.');
  const encode=v=>v===null?{nullValue:null}:typeof v==='boolean'?{booleanValue:v}:typeof v==='object'?{mapValue:{fields:Object.fromEntries(Object.entries(v).map(([k,x])=>[k,encode(x)]))}}:{stringValue:v};
  const fixtures=[
    ['persons/demo7-link-active',{displayName:'[Prueba] Persona libre activa',isActive:true,linkedUid:null,notes:'DEMO: disponible para vincular.',createdBy:uid,updatedBy:uid},['createdAt','updatedAt']],
    ['persons/demo7-link-inactive',{displayName:'[Prueba] Persona libre inactiva',isActive:false,linkedUid:null,notes:'DEMO: vinculación con advertencia.',createdBy:uid,updatedBy:uid},['createdAt','updatedAt']],
    ['persons/demo7-link-admin-person',{displayName:'[Prueba] Persona de admin ficticio',isActive:true,linkedUid:'demo7-link-admin',notes:'DEMO: al inactivarla, el admin debe pasar a miembro.',createdBy:uid,updatedBy:uid},['createdAt','updatedAt']],
    ['members/demo7-link-admin',{uid:'demo7-link-admin',displayName:'[Prueba] Admin ficticio para vínculos',role:'admin',status:'active',personId:'demo7-link-admin-person'},['joinedAt','updatedAt']],
    ['auditEvents/demo-links-provisioned',{action:'system.linksDemoPrepared',entityType:'group',entityId:groupId,actorUid:'system:seed-links-demo',before:null,after:{note:'DEMO: dos personas libres y admin ficticio con persona propia.'}},['createdAt']],
  ];
  if(process.argv.includes('--apply')){
    const writes=fixtures.map(([suffix,fields,times])=>({update:{name:`${root}/${suffix}`,fields:Object.fromEntries(Object.entries(fields).map(([k,v])=>[k,encode(v)]))},currentDocument:{exists:false},
      updateTransforms:times.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))}));
    await api.post(`${root.split('/groups/')[0]}:commit`,{writes},hide());
  }
  if(process.argv.includes('--verify'))for(const[suffix]of fixtures)await api.get(`${root}/${suffix}`,hide());
  console.log(JSON.stringify({groupId,applied:process.argv.includes('--apply'),verified:process.argv.includes('--verify'),documents:fixtures.map(([id])=>id),overwrites:0,realAuthAccountsCreated:0}));
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
