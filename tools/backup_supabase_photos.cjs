// One-off backup only. Does not change photos, buckets, policies or secrets.
const fs=require('node:fs/promises'),path=require('node:path'),os=require('node:os');
const {createHash}=require('node:crypto');
const {photos,PHOTOS,BUCKET}=require('./operator_supabase.cjs');
const digest=bytes=>createHash('sha256').update(bytes).digest('hex');
const catalog=rows=>JSON.stringify(rows.map(r=>[r.name,r.id,r.updated_at]));
async function main(){
  const cli=process.argv[2],storage=await photos(cli),before=await storage.list();
  const directory=path.join(os.homedir(),'Documents/BoteParroquial-backups/photos',new Date().toISOString().replace(/[:.]/g,'-'));
  await fs.mkdir(path.dirname(directory),{recursive:true});await fs.mkdir(directory);
  const objects=[];
  for(const item of before) {
    const response=await storage.download(item.name),bytes=Buffer.from(await response.arrayBuffer());
    const file=`${digest(Buffer.from(item.name))}.bin`,sha256=digest(bytes);
    await fs.writeFile(path.join(directory,file),bytes,{flag:'wx',mode:0o600});
    if(digest(await fs.readFile(path.join(directory,file)))!==sha256)throw new Error('photo_backup_verification_failed');
    objects.push({name:item.name,file,sha256,bytes:bytes.length,contentType:response.headers.get('content-type'),metadata:item});
  }
  const after=await storage.list();
  if(catalog(before)!==catalog(after))throw new Error('photos_changed_during_backup');
  const data=Buffer.from(JSON.stringify({format:'boteparroquial.photos-backup/v1',projectRef:PHOTOS,bucket:BUCKET,objects}));
  await fs.writeFile(path.join(directory,'photos.json'),data,{flag:'wx',mode:0o600});
  const manifest={projectRef:PHOTOS,bucket:BUCKET,createdAt:new Date().toISOString(),objects:objects.length,bytes:objects.reduce((sum,o)=>sum+o.bytes,0),sha256:digest(data),verified:true,containsSecrets:false};
  await fs.writeFile(path.join(directory,'manifest.json'),JSON.stringify(manifest,null,2),{flag:'wx'});
  await fs.writeFile(path.join(directory,'README.txt'),'Copia puntual privada antes del reinicio, no copia semanal. photos.json conserva clave original, tipo MIME y huella de cada archivo binario.\nNo incluye claves o configuración de Supabase. No restaurar sobrescribiendo fotos posteriores sin autorización expresa.\n',{flag:'wx'});
  console.log(JSON.stringify({directory,...manifest}));
}
if(require.main===module)main().catch(()=>{console.error('No se completó la copia de fotos. No se ha borrado ni modificado ninguna foto.');process.exitCode=1;});
module.exports={digest,catalog};
