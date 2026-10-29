// Offline validation by default; explicit restoration into an EMPTY bucket only.
const fs=require('node:fs/promises'),path=require('node:path');
const {photos,PHOTOS,BUCKET}=require('./operator_supabase.cjs');
const {digest}=require('./backup_supabase_photos.cjs');
async function validate(directory){
  if(!path.isAbsolute(directory))throw new Error('absolute_directory_required');
  const manifest=JSON.parse(await fs.readFile(path.join(directory,'manifest.json'),'utf8')),bytes=await fs.readFile(path.join(directory,'photos.json'));
  if(!manifest.verified||manifest.projectRef!==PHOTOS||manifest.bucket!==BUCKET||digest(bytes)!==manifest.sha256)throw new Error('invalid_photo_manifest');
  const data=JSON.parse(bytes),names=new Set();
  if(data.format!=='boteparroquial.photos-backup/v1'||data.objects?.length!==manifest.objects)throw new Error('invalid_photo_catalog');
  for(const object of data.objects){
    if(!/^[a-f0-9]{64}\.bin$/.test(object.file)||typeof object.name!=='string'||!object.name.startsWith('groups/')&&!object.name.startsWith('accounts/')||object.name.split('/').some(p=>!p||['.','..'].includes(p))||names.has(object.name))throw new Error('invalid_photo_path');
    const bytes=await fs.readFile(path.join(directory,object.file));
    if(bytes.length!==object.bytes||digest(bytes)!==object.sha256||!['image/jpeg','image/png','image/webp'].includes(object.contentType?.split(';')[0]))throw new Error('photo_hash_mismatch');
    names.add(object.name);
  }
  return data;
}
async function main(){
  const args=process.argv.slice(2),data=await validate(args[0]);
  if(!args.includes('--apply')){console.log(JSON.stringify({mode:'validated-plan',projectRef:PHOTOS,objects:data.objects.length,remoteWrites:0}));return;}
  if(args.length!==5||args[2]!=='--apply'||args[3]!=='--confirm'||args[4]!==PHOTOS)throw new Error('explicit_photo_confirmation_required');
  const storage=await photos(args[1]);
  if((await storage.list()).length)throw new Error('restoration_requires_empty_bucket');
  for(const object of data.objects){
    const bytes=await fs.readFile(path.join(args[0],object.file));
    await storage.upload(object.name,bytes,object.contentType);
    const restored=Buffer.from(await(await storage.download(object.name)).arrayBuffer());
    if(digest(restored)!==object.sha256)throw new Error('photo_restore_not_verified');
  }
  console.log(JSON.stringify({mode:'restored-and-verified',projectRef:PHOTOS,objects:data.objects.length}));
}
module.exports={validate};
if(require.main===module)main().catch(()=>{console.error('Restauración de fotos no completada. No se ha borrado ningún archivo. Revisa manifiesto y que el bucket esté vacío.');process.exitCode=1;});
