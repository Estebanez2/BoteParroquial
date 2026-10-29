// Operator only. Default is a review plan; never creates keys or changes billing.
const path = require('node:path');
const fs = require('node:fs/promises');
const cli = path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount} = require(path.join(cli,'auth'));
const {requireAuth} = require(path.join(cli,'requireAuth'));
const {Client} = require(path.join(cli,'apiv2'));
const project='boteparroquial', accountId='boteparroquial-notifications';
const email=`${accountId}@${project}.iam.gserviceaccount.com`;
const roleId='BoteParroquialNotifications';
const permissions=['cloudmessaging.messages.create','datastore.databases.get','datastore.entities.get','datastore.entities.list','datastore.entities.create','datastore.entities.update'];
let stage='authentication';
(async()=>{
  await requireAuth({project,...getGlobalDefaultAccount(),nonInteractive:true});
  const iam=new Client({urlPrefix:'https://iam.googleapis.com',apiVersion:'v1'});
  const crm=new Client({urlPrefix:'https://cloudresourcemanager.googleapis.com',apiVersion:'v1'});
  const roleName=`projects/${project}/roles/${roleId}`;
  const policy=(await crm.post(`projects/${project}:getIamPolicy`,{options:{requestedPolicyVersion:3}},{skipLog:{reqBody:true,resBody:true}})).body;
  if(!process.argv.includes('--apply')){console.log(JSON.stringify({project,serviceAccount:email,customRole:roleName,permissions,changesApplied:false,createsKeys:false}));return;}
  const backup=process.argv[process.argv.indexOf('--backup')+1];
  if(!path.isAbsolute(backup||''))throw new Error('Falta carpeta absoluta de respaldo.');
  const manifest=JSON.parse(await fs.readFile(path.join(backup,'manifest.json'),'utf8'));
  if(manifest.project!==project||!manifest.verifiedAgainstActiveRelease)throw new Error('Respaldo no verificado.');
  await fs.writeFile(path.join(backup,`iam-before-notifications-${Date.now()}.json`),JSON.stringify(policy,null,2),{flag:'wx'});
  let role;
  stage='custom_role';
  try{role=(await iam.get(roleName,{skipLog:{resBody:true}})).body;}catch(e){if(e.status!==404)throw e;}
  if(role){if(JSON.stringify([...role.includedPermissions].sort())!==JSON.stringify([...permissions].sort()))throw new Error('El rol existente difiere; no se amplía o sustituye automáticamente.');}
  else await iam.post(`projects/${project}/roles`,{roleId,role:{title:'BoteParroquial notifications worker',description:'Server notifications only; no delete, Auth admin, IAM or Rules administration.',includedPermissions:permissions,stage:'GA'}},{skipLog:{reqBody:true,resBody:true}});
  stage='service_account';
  try{await iam.get(`projects/${project}/serviceAccounts/${email}`,{skipLog:{resBody:true}});}catch(e){
    if(e.status!==404)throw e;
    await iam.post(`projects/${project}/serviceAccounts`,{accountId,serviceAccount:{displayName:'BoteParroquial notification worker'}},{skipLog:{reqBody:true,resBody:true}});
  }
  const member=`serviceAccount:${email}`;
  stage='policy_binding';
  const bindings=policy.bindings||[];
  if(!bindings.some(b=>b.role===roleName&&!b.condition&&b.members.includes(member))){
    const current=bindings.find(b=>b.role===roleName&&!b.condition);
    if(current)current.members.push(member);else bindings.push({role:roleName,members:[member]});
    await crm.post(`projects/${project}:setIamPolicy`,{policy:{...policy,bindings}},{skipLog:{reqBody:true,resBody:true}});
  }
  console.log(JSON.stringify({serviceAccount:email,role:roleName,permissions,identityConfigured:true,keysCreated:false,backup}));
})().catch(e=>{
  // These endpoints never return private keys. Expose only the operation and
  // concise API error, never a policy dump or authorization headers.
  const message=String(e.message||'unavailable').replace(/ya29\.[A-Za-z0-9._-]+/g,'[redacted]').slice(0,600);
  console.error(JSON.stringify({stage,status:e.status||null,message}));process.exitCode=1;
});
