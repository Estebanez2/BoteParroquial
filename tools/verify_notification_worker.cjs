// Operator verification: Vault secret stays in child-process memory, never logs.
const {spawnSync}=require('node:child_process');
const cli=process.argv[2],ref='qngrmxfjckrrfiyioyzl';
(async()=>{
  const result=spawnSync(cli,['db','query','--linked','--project-ref',ref,'--output','json',"select decrypted_secret as secret from vault.decrypted_secrets where name='boteparroquial_worker_secret'"],{encoding:'utf8',windowsHide:true,timeout:30000,input:''});
  if(result.status!==0)throw new Error('vault_read_failed');
  const data=JSON.parse(result.stdout);
  const secret=(data.rows??data)[0]?.secret;
  if(typeof secret!=='string'||secret.length<40)throw new Error('worker_secret_unavailable');
  const response=await fetch(`https://${ref}.supabase.co/functions/v1/notification-worker`,{
    method:'POST',headers:{'Content-Type':'application/json','x-worker-secret':secret},body:'{}',signal:AbortSignal.timeout(120000),
  });
  const body=await response.json();
  console.log(JSON.stringify({projectRef:ref,status:response.status,processed:body.processed??null,failed:body.failed??null,error:body.error??null,code:body.code??null,upstreamStatus:body.status??null,failuresByCode:body.failuresByCode??null}));
  if(!response.ok||body.failed!==0)process.exitCode=1;
})().catch(()=>{console.error('No se pudo verificar el worker autenticado. Ningún secreto se ha impreso.');process.exitCode=1;});
