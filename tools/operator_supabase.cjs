// Operator-only helpers. Keys remain in this process, never arguments or logs.
const {spawnSync}=require('node:child_process');
const path=require('node:path');
const PHOTOS='ietnizafvtovelyuxbvk',NOTIFICATIONS='qngrmxfjckrrfiyioyzl',BUCKET='boteparroquial-photos';
function command(cli,args) {
  if(!path.isAbsolute(cli)||!cli.endsWith('supabase.exe'))throw new Error('invalid_cli');
  const result=spawnSync(cli,args,{encoding:'utf8',windowsHide:true,input:'',timeout:60000,maxBuffer:8*1024*1024,env:{...process.env,DEBUG:''}});
  if(result.status!==0)throw new Error('supabase_operator_command_failed');
  return JSON.parse(result.stdout);
}
async function photos(cli) {
  const keys=command(cli,['projects','api-keys','--project-ref',PHOTOS,'--output','json']);
  const key=keys.find(k=>k.name==='service_role')?.api_key;
  if(typeof key!=='string'||key.length<40)throw new Error('storage_operator_key_missing');
  const base=`https://${PHOTOS}.supabase.co/storage/v1`;
  async function request(method,suffix,body,extra={}) {
    const response=await fetch(`${base}/${suffix}`,{method,headers:{Authorization:`Bearer ${key}`,apikey:key,...extra},
      body,redirect:'error',signal:AbortSignal.timeout(20000)});
    if(!response.ok)throw new Error('storage_operator_request_failed');
    return response;
  }
  const bucket=await(await request('GET',`bucket/${BUCKET}`)).json();
  if(bucket.id!==BUCKET||bucket.public!==false)throw new Error('unexpected_private_bucket');
  async function list() {
    const files=[],seen=new Set();
    async function visit(prefix,depth) {
      if(depth>10||seen.has(prefix))throw new Error('invalid_storage_catalog');seen.add(prefix);
      let offset=0;
      while(true) {
        const rows=await(await request('POST',`object/list/${BUCKET}`,JSON.stringify({prefix,limit:100,offset,sortBy:{column:'name',order:'asc'}}),{'Content-Type':'application/json'})).json();
        if(!Array.isArray(rows))throw new Error('invalid_storage_catalog');
        for(const row of rows) {
          if(typeof row.name!=='string'||!row.name||/[\/\\\x00-\x1f]/.test(row.name)||['.','..'].includes(row.name))throw new Error('invalid_storage_name');
          const name=prefix+row.name;
          if(row.id===null)await visit(`${name}/`,depth+1);
          else if(typeof row.id==='string')files.push({...row,name});
          else throw new Error('invalid_storage_catalog');
        }
        if(rows.length<100)break;
        offset+=rows.length;
        if(offset>100000||files.length>100000)throw new Error('storage_catalog_limit');
      }
    }
    await visit('',0);
    return files.sort((a,b)=>a.name.localeCompare(b.name));
  }
  return {list,
    download:name=>request('GET',`object/${BUCKET}/${name.split('/').map(encodeURIComponent).join('/')}`),
    upload:async(name,bytes,contentType)=>{await request('POST',`object/${BUCKET}/${name.split('/').map(encodeURIComponent).join('/')}`,bytes,{'Content-Type':contentType});},
    remove:async names=>{await request('DELETE',`object/${BUCKET}`,JSON.stringify({prefixes:names}),{'Content-Type':'application/json'});},
  };
}
module.exports={command,photos,PHOTOS,NOTIFICATIONS,BUCKET};
