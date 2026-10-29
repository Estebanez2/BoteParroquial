// Explicit TEST reset. Requires verified recoverable copies, paused worker and
// temporarily closed client Rules. Never calls Auth, IAM, bucket/config deletion.
const fs=require('node:fs/promises'),path=require('node:path');
const {createHash}=require('node:crypto'),{isDeepStrictEqual}=require('node:util');
const {validate:firestoreCopy}=require('./restore_firestore_data.cjs');
const {validate:photosCopy}=require('./restore_supabase_photos.cjs');
const {photos,command,NOTIFICATIONS,PHOTOS}=require('./operator_supabase.cjs');
const {firebaseClient,snapshot,adapter,ROOT,PROJECT,route}=require('./backup_firestore_data.cjs');
const MAINTENANCE="rules_version = '2';\nservice cloud.firestore { match /databases/{database}/documents { match /{document=**} { allow read, write: if false; } } }\n";
const digest=bytes=>createHash('sha256').update(bytes).digest('hex');
function encode(value){
  if(value===null)return {nullValue:null};
  if(typeof value==='boolean')return {booleanValue:value};
  if(typeof value==='number'){
    if(!Number.isSafeInteger(value))throw new Error('demo_integer_required');
    return {integerValue:String(value)};
  }
  if(typeof value==='string')return /^2026-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/.test(value)?{timestampValue:value}:{stringValue:value};
  if(Array.isArray(value))return {arrayValue:{values:value.map(encode)}};
  if(value&&typeof value==='object')return {mapValue:{fields:fields(value)}};
  throw new Error('unsupported_demo_value');
}
const fields=data=>Object.fromEntries(Object.entries(data).map(([key,value])=>[key,encode(value)]));
function canonical(value){
  if(Array.isArray(value))return value.map(canonical);
  if(!value||typeof value!=='object')return value;
  return Object.fromEntries(Object.entries(value).sort(([a],[b])=>a.localeCompare(b)).map(([k,v])=>[k,k==='timestampValue'?new Date(v).toISOString():canonical(v)]));
}
async function activeRules(){
  const cli=path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
  const {Client}=require(path.join(cli,'apiv2'));
  const api=new Client({urlPrefix:'https://firebaserules.googleapis.com',apiVersion:'v1'});
  const release=(await api.get(`projects/${PROJECT}/releases/cloud.firestore`,{skipLog:{resBody:true}})).body;
  const set=(await api.get(release.rulesetName,{skipLog:{resBody:true}})).body;
  return set.source?.files?.find(f=>f.name==='firestore.rules'||f.name==='maintenance.rules')?.content;
}
async function main(){
  const args=process.argv.slice(2),[firestoreDirectory,photoDirectory,cli]=args;
  const saved=await firestoreCopy(firestoreDirectory),savedPhotos=await photosCopy(photoDirectory);
  const bytes=await fs.readFile('.dart_tool/demo-dataset.json'),demo=JSON.parse(bytes),validated=JSON.parse(await fs.readFile('.dart_tool/demo-domain-validation.json','utf8'));
  if(demo.format!=='boteparroquial.demo/v1'||demo.groups.length!==2||demo.owner!=='JDQpjp5XtFTDOoVgK5Rbc9EGUHB2'||!Array.isArray(validated)||validated.length!==2||validated.some(g=>demo.groups.find(d=>d.id===g.groupId)?.balanceCents!==g.balanceCents))throw new Error('demo_validation_missing');
  const names=new Set();
  const writes=demo.documents.map(doc=>{
    if(!/^(groups\/(demo-comunidad-20261020|demo-jovenes-20261020)(\/|$)|users\/JDQpjp5XtFTDOoVgK5Rbc9EGUHB2$)/.test(doc.path)||doc.path.split('/').length%2!==0||doc.path.split('/').some(p=>!p||['.','..'].includes(p))||names.has(doc.path))throw new Error('invalid_demo_scope');
    names.add(doc.path);return {update:{name:`${ROOT}/${doc.path}`,fields:fields(doc.data)},currentDocument:{exists:false}};
  });
  const report={mode:'validated-plan',project:PROJECT,photosProject:PHOTOS,firestoreBackup:firestoreDirectory,photoBackup:photoDirectory,documentsToDelete:saved.documents.length,photosToDelete:savedPhotos.objects.length,documentsToCreate:writes.length,groups:demo.groups,datasetSha256:digest(bytes),authAccountsTouched:0,configurationDeleted:false};
  if(!args.includes('--apply')){console.log(JSON.stringify(report));return;}
  if(args.length!==6||args[3]!=='--apply'||args[4]!=='--confirm'||args[5]!==PROJECT)throw new Error('explicit_reset_confirmation_required');
  const api=await firebaseClient();
  if((await activeRules())?.trim()!==MAINTENANCE.trim())throw new Error('maintenance_rules_required');
  const cron=command(cli,['db','query','--linked','--project-ref',NOTIFICATIONS,'--output','json',"select active from cron.job where jobname='boteparroquial-notifications'"]);
  if((cron.rows??cron)[0]?.active!==false)throw new Error('paused_worker_required');
  const current=await snapshot(adapter(api));
  const expected=new Map(saved.documents.map(d=>[d.name,d]));
  if(current.documents.length!==expected.size||current.documents.some(d=>d.updateTime!==expected.get(d.name)?.updateTime||!isDeepStrictEqual(d.fields,expected.get(d.name)?.fields)))throw new Error('firestore_changed_since_backup');
  if(current.documents.some(d=>Date.parse(d.fields?.leaseUntil?.timestampValue)>Date.now()))throw new Error('worker_lease_still_active');
  const storage=await photos(cli),objects=await storage.list(),photoNames=new Map(savedPhotos.objects.map(o=>[o.name,o]));
  if(objects.length!==photoNames.size||objects.some(o=>o.id!==photoNames.get(o.name)?.metadata.id||o.updated_at!==photoNames.get(o.name)?.metadata.updated_at))throw new Error('photos_changed_since_backup');
  report.mode='reset-in-progress';report.startedAt=new Date().toISOString();
  const checkpoint=()=>fs.writeFile('.dart_tool/demo-reset-result.json',JSON.stringify(report,null,2));
  await checkpoint();
  const deletions=current.documents.sort((a,b)=>b.name.split('/').length-a.name.split('/').length).map(d=>({delete:d.name,currentDocument:{updateTime:d.updateTime}}));
  for(let i=0;i<deletions.length;i+=200){await api.post(`${route(ROOT)}:commit`,{writes:deletions.slice(i,i+200)},{skipLog:{body:true,resBody:true}});}
  report.documentsDeleted=deletions.length;await checkpoint();
  if((await snapshot(adapter(api))).documents.length)throw new Error('database_not_empty_after_reset');
  for(let i=0;i<objects.length;i+=100)await storage.remove(objects.slice(i,i+100).map(o=>o.name));
  if((await storage.list()).length)throw new Error('photos_not_empty_after_reset');
  report.photosDeleted=objects.length;await checkpoint();
  for(let i=0;i<writes.length;i+=200){await api.post(`${route(ROOT)}:commit`,{writes:writes.slice(i,i+200)},{skipLog:{body:true,resBody:true}});report.documentsCreated=Math.min(i+200,writes.length);await checkpoint();}
  for(let i=0;i<writes.length;i+=100){
    const chunk=writes.slice(i,i+100),reply=(await api.post(`${route(ROOT)}:batchGet`,{documents:chunk.map(w=>w.update.name)},{skipLog:{body:true,resBody:true}})).body;
    const found=new Map(reply.filter(r=>r.found).map(r=>[r.found.name,r.found.fields]));
    if(found.size!==chunk.length||chunk.some(w=>!isDeepStrictEqual(canonical(w.update.fields),canonical(found.get(w.update.name)))))throw new Error('seed_readback_mismatch');
  }
  report.mode='reset-and-seed-verified';report.completedAt=new Date().toISOString();report.photosRemaining=0;await checkpoint();
  console.log(JSON.stringify(report));
}
module.exports={MAINTENANCE,fields};
if(require.main===module)main().catch(error=>{console.error(JSON.stringify({error:String(error.message),project:PROJECT,note:'No automatic retry or restoration. Check checkpoint and recoverable copies before proceeding.'}));process.exitCode=1;});
