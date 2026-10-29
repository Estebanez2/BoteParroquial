// Read-only final infrastructure evidence. Never prints API keys or Vault values.
const fs=require('node:fs/promises');
const {command,photos,PHOTOS,NOTIFICATIONS}=require('./operator_supabase.cjs');
const {firebaseClient,ROOT,route}=require('./backup_firestore_data.cjs');
async function main(){
  const cli=process.argv[2],api=await firebaseClient(),quiet={skipLog:{body:true,resBody:true}};
  const result={checkedAt:new Date().toISOString(),functions:{},cron:null,photos:0,groups:[],unauthenticated:{}};
  for(const ref of [PHOTOS,NOTIFICATIONS]){
    const list=command(cli,['functions','list','--project-ref',ref,'--output','json']);
    result.functions[ref]=list.map(f=>({name:f.name,version:f.version,status:f.status,verifyJwt:f.verify_jwt}));
  }
  const cron=command(cli,['db','query','--linked','--project-ref',NOTIFICATIONS,'--output','json',"select jobname,schedule,active from cron.job where jobname='boteparroquial-notifications'"]);
  result.cron=(cron.rows??cron)[0];
  if(result.cron?.active!==true||result.cron.schedule!=='*/15 * * * *')throw new Error('cron_not_restored');
  result.photos=(await(await photos(cli)).list()).length;
  if(result.photos!==0)throw new Error('old_photos_remain');
  for(const [ref,name]of [[PHOTOS,'photo-access'],[PHOTOS,'lifecycle-cleanup'],[NOTIFICATIONS,'notification-worker']]){
    const response=await fetch(`https://${ref}.supabase.co/functions/v1/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}',signal:AbortSignal.timeout(20000)});
    result.unauthenticated[name]=response.status;if(response.status!==401)throw new Error('unauthenticated_function_not_denied');
  }
  for(const id of ['demo-comunidad-20261020','demo-jovenes-20261020']){
    const counts={id};
    for(const collection of ['persons','movements','allocations','notifications','notificationWorker']){
      const body=(await api.post(`${route(ROOT)}/groups/${id}:runAggregationQuery`,{structuredAggregationQuery:{structuredQuery:{from:[{collectionId:collection}]},aggregations:[{alias:'total',count:{}}]}},quiet)).body;
      counts[collection]=Number(body.find(r=>r.result)?.result.aggregateFields.total.integerValue);
    }
    result.groups.push(counts);
  }
  await fs.writeFile('.dart_tool/completion-remote-state.json',JSON.stringify(result,null,2));console.log(JSON.stringify(result));
}
main().catch(error=>{console.error(JSON.stringify({error:error.message}));process.exitCode=1;});
