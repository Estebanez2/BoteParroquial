// Explicit operator restoration into an EMPTY database only. Never deletes.
const fs=require('node:fs/promises'),path=require('node:path');
const {createHash}=require('node:crypto');
const {isDeepStrictEqual}=require('node:util');
const {snapshot,adapter,firebaseClient,ROOT,PROJECT,route}=require('./backup_firestore_data.cjs');
async function validate(directory){
  if(!path.isAbsolute(directory))throw new Error('absolute_backup_directory_required');
  const manifest=JSON.parse(await fs.readFile(path.join(directory,'manifest.json'),'utf8'));
  const bytes=await fs.readFile(path.join(directory,'firestore.json'));
  if(!manifest.verified||manifest.project!==PROJECT||createHash('sha256').update(bytes).digest('hex')!==manifest.sha256)throw new Error('backup_manifest_mismatch');
  const data=JSON.parse(bytes),names=new Set();
  if(data.format!=='boteparroquial.firestore-backup/v1'||data.project!==PROJECT||!Array.isArray(data.documents)||data.documents.length!==manifest.documents)throw new Error('invalid_backup');
  for(const doc of data.documents){
    const suffix=doc.name?.slice(ROOT.length+1),parts=suffix?.split('/');
    if(!doc.name?.startsWith(`${ROOT}/`)||!parts?.length||parts.length%2!==0||parts.some(p=>!p||['.','..'].includes(p))||names.has(doc.name)||!doc.fields||typeof doc.fields!=='object')throw new Error('invalid_backup_document');
    names.add(doc.name);
  }
  return data;
}
async function main(){
  const args=process.argv.slice(2),directory=args[0],apply=args.includes('--apply');
  const data=await validate(directory);
  if(!apply){console.log(JSON.stringify({mode:'validated-plan',project:PROJECT,documents:data.documents.length,deletes:0,authAccounts:0}));return;}
  if(args.length!==4||args[1]!=='--apply'||args[2]!=='--confirm'||args[3]!==PROJECT)throw new Error('explicit_project_confirmation_required');
  const api=await firebaseClient(),existing=await snapshot(adapter(api));
  if(existing.documents.length!==0)throw new Error('restoration_requires_empty_database');
  for(let i=0;i<data.documents.length;i+=200){
    const writes=data.documents.slice(i,i+200).map(doc=>({update:{name:doc.name,fields:doc.fields},currentDocument:{exists:false}}));
    await api.post(`${route(ROOT)}:commit`,{writes},{skipLog:{body:true,resBody:true}});
  }
  const restored=await snapshot(adapter(api)),expected=new Map(data.documents.map(d=>[d.name,d.fields]));
  if(restored.documents.length!==expected.size||restored.documents.some(d=>!isDeepStrictEqual(d.fields,expected.get(d.name))))throw new Error('restoration_not_verified');
  console.log(JSON.stringify({mode:'restored-and-verified',project:PROJECT,documents:restored.documents.length}));
}
module.exports={validate};
if(require.main===module)main().catch(()=>{console.error('Restauración no completada. No se han borrado documentos. Revisa copia, sesión y que la base esté vacía; no fuerces una copia parcial.');process.exitCode=1;});
