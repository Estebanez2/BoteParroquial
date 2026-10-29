// Operator setup. No passwords in arguments, source, stdout or project files.
const {spawnSync} = require('node:child_process');
const {randomBytes} = require('node:crypto');
const fs = require('node:fs');
const cli = process.argv[2];
function run(args, env = process.env) {
  const result = spawnSync(cli, args, {env, encoding:'utf8',windowsHide:true,timeout:60000,input:'',maxBuffer:2*1024*1024});
  if (result.status !== 0) {
    let diagnostic = String(result.stderr || result.error?.message || 'Sin detalle');
    if (env.SUPABASE_DB_PASSWORD) diagnostic=diagnostic.replaceAll(env.SUPABASE_DB_PASSWORD,'[redacted]');
    diagnostic=diagnostic.replace(/sbp_[A-Za-z0-9_-]+|sb_secret_[A-Za-z0-9_-]+/g,'[redacted]');
    fs.writeFileSync('.dart_tool/notification-project-error.log',diagnostic);
    throw new Error(`CLI ${args.slice(0,2).join(' ')}: estado ${result.status}; diagnóstico redactado en .dart_tool/notification-project-error.log`);
  }
  return JSON.parse(result.stdout);
}
try {
  const projects = run(['projects','list','--output','json']);
  const photos = projects.find(p=>p.id==='ietnizafvtovelyuxbvk');
  if (!photos) throw new Error('No se identifica el proyecto de fotos autorizado.');
  const existing = projects.find(p=>p.name==='BoteParroquialNotifications' && p.organization_id===photos.organization_id);
  if (existing) { console.log(JSON.stringify({ref:existing.id,reused:true,status:existing.status})); process.exit(0); }
  if (projects.filter(p=>p.status!=='INACTIVE').length>=2) throw new Error('No hay un segundo proyecto gratuito disponible; no se cambia el plan.');
  if (!process.argv.includes('--apply')) { console.log(JSON.stringify({plan:'create separate free project',name:'BoteParroquialNotifications',organization:photos.organization_id,region:photos.region})); process.exit(0); }
  // Database access uses Management API; a random DB password is never needed by
  // Flutter/worker. The operator can reset it in Console if direct SQL is needed.
  const env={...process.env,SUPABASE_DB_PASSWORD:randomBytes(32).toString('hex')};
  const created = run(['projects','create','BoteParroquialNotifications','--org-id',photos.organization_id,'--region',photos.region,'--output','json','--yes'],env);
  delete env.SUPABASE_DB_PASSWORD;
  if (!created.id || created.id===photos.id) throw new Error('No se confirma un proyecto aislado.');
  const info={ref:created.id,name:created.name,organization:photos.organization_id,region:created.region,status:created.status};
  fs.writeFileSync('.dart_tool/notification-project.json',JSON.stringify(info,null,2),{flag:'wx'});
  console.log(JSON.stringify(info));
} catch (e) { console.error(e.message);process.exitCode=1; }
