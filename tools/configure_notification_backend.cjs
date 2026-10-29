// Operator only: isolated project, ephemeral private transfer, no secret output.
// Requires the reviewed dedicated Firebase identity to exist already.
const fs=require('node:fs/promises'),path=require('node:path'),os=require('node:os');
const {spawnSync}=require('node:child_process');
const {randomBytes}=require('node:crypto');
const firebaseLib=path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount}=require(path.join(firebaseLib,'auth'));
const {requireAuth}=require(path.join(firebaseLib,'requireAuth'));
const {Client}=require(path.join(firebaseLib,'apiv2'));
const cli=process.argv[2],ref=process.argv[3],backup=process.argv[4];
const firebaseProject='boteparroquial';
const email='boteparroquial-notifications@boteparroquial.iam.gserviceaccount.com';
let temporary,manifestPath,metadata;
function run(args){
  const result=spawnSync(cli,args,{encoding:'utf8',windowsHide:true,input:'',timeout:180000,maxBuffer:4*1024*1024});
  if(result.status!==0)throw new Error(`supabase_${args.slice(0,2).join('_')}_failed`);
  return result.stdout;
}
async function checkpoint(){await fs.writeFile(manifestPath,JSON.stringify(metadata,null,2));}
(async()=>{
  if(!cli||!path.isAbsolute(cli)||!path.isAbsolute(backup||'')||!/^[a-z]{20}$/.test(ref||'')||ref==='ietnizafvtovelyuxbvk')throw new Error('invalid_isolated_target');
  const projects=JSON.parse(run(['projects','list','--output','json']));
  const target=projects.find(p=>p.id===ref),photos=projects.find(p=>p.id==='ietnizafvtovelyuxbvk');
  if(ref!=='qngrmxfjckrrfiyioyzl'||!target||!photos||target.organization_id!==photos.organization_id||!['BoteParroquialNotifications','BoteParroquialNotificaciones'].includes(target.name)||target.status!=='ACTIVE_HEALTHY')throw new Error('isolated_project_not_ready');
  if(!process.argv.includes('--apply')){console.log(JSON.stringify({ref,project:target.name,mode:'plan',createsDedicatedKey:true,secretDestination:'isolated Edge secrets and Vault',enablesCron:false}));return;}
  const backupInfo=JSON.parse(await fs.readFile(path.join(backup,'manifest.json'),'utf8'));
  if(backupInfo.project!==firebaseProject||!backupInfo.verifiedAgainstActiveRelease)throw new Error('missing_verified_backup');
  await requireAuth({project:firebaseProject,...getGlobalDefaultAccount(),nonInteractive:true});
  const iam=new Client({urlPrefix:'https://iam.googleapis.com',apiVersion:'v1'});
  const role=(await iam.get(`projects/${firebaseProject}/roles/BoteParroquialNotifications`,{skipLog:{resBody:true}})).body;
  if(!role.includedPermissions?.includes('cloudmessaging.messages.create')||role.includedPermissions.some(p=>/delete|setIamPolicy|rules|firebaseauth/.test(p)))throw new Error('unexpected_identity_permissions');
  temporary=await fs.mkdtemp(path.join(os.tmpdir(),'BoteParroquial-worker-'));
  manifestPath=path.join(backup,`notification-backend-${Date.now()}.json`);
  metadata={createdAt:new Date().toISOString(),projectRef:ref,serviceAccount:email,keysCreated:false,secretsUploaded:false,vaultConfigured:false,workerDeployed:false,cronEnabled:false};
  await checkpoint();
  const key=(await iam.post(`projects/${firebaseProject}/serviceAccounts/${email}/keys`,{privateKeyType:'TYPE_GOOGLE_CREDENTIALS_FILE'},{skipLog:{reqBody:true,resBody:true}})).body;
  metadata.keyName=key.name;metadata.keysCreated=true;await checkpoint();
  const credentials=Buffer.from(key.privateKeyData,'base64').toString('utf8');
  const secret=randomBytes(32).toString('hex'),activation=new Date().toISOString();
  const envPath=path.join(temporary,'worker.env');
  // JSON carries literal escaped newlines; dotenv single quotes preserve them.
  await fs.writeFile(envPath,`NOTIFICATION_FIREBASE_CREDENTIALS='${credentials.replace(/\r?\n/g,'')}'\nNOTIFICATION_WORKER_SECRET=${secret}\nNOTIFICATION_STARTED_AT=${activation}\n`,{mode:0o600,flag:'wx'});
  run(['secrets','set','--project-ref',ref,'--env-file',envPath]);
  metadata.secretsUploaded=true;metadata.startedAt=activation;await checkpoint();
  const url=`https://${ref}.supabase.co/functions/v1/notification-worker`;
  const sqlPath=path.join(temporary,'vault.sql');
  const sql=`select vault.create_secret('${url}','boteparroquial_worker_url');\nselect vault.create_secret('${secret}','boteparroquial_worker_secret');`;
  await fs.writeFile(sqlPath,sql,{mode:0o600,flag:'wx'});
  run(['db','query','--linked','--project-ref',ref,'--file',sqlPath]);
  metadata.vaultConfigured=true;await checkpoint();
  run(['functions','deploy','notification-worker','--project-ref',ref,'--no-verify-jwt','--use-api']);
  metadata.workerDeployed=true;await checkpoint();
  const unauthorized=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
  if(unauthorized.status!==401)throw new Error('worker_authentication_not_verified');
  const response=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json','x-worker-secret':secret},body:'{}',signal:AbortSignal.timeout(120000)});
  const result=await response.json();
  if(!response.ok||result.failed!==0)throw new Error('worker_invocation_not_verified');
  metadata.invocationVerified=true;metadata.processed=result.processed;await checkpoint();
  // Cron remains an explicit later action after reviewing this successful state.
  console.log(JSON.stringify({...metadata,manifestPath}));
})().catch(async()=>{
  if(metadata){metadata.requiresReview=true;await checkpoint().catch(()=>{});}
  console.error('No se completó la configuración. Revisar el manifest privado de etapas/ID de clave; no se han impreso secretos ni activado cron.');process.exitCode=1;
}).finally(async()=>{
  if(!temporary)return;
  const absolute=path.resolve(temporary),expected=path.resolve(os.tmpdir())+path.sep;
  if(!absolute.startsWith(expected)||!path.basename(absolute).startsWith('BoteParroquial-worker-'))return;
  for(const name of ['worker.env','vault.sql'])await fs.unlink(path.join(absolute,name)).catch(()=>{});
  await fs.rmdir(absolute).catch(()=>{});
});
