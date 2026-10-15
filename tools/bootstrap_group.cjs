// Operator-only tool. Uses the existing Firebase CLI login, never app credentials.
// Dry run: node tools/bootstrap_group.cjs --name Prueba1
// Apply: append --apply. Requires the matching users/{uid} profile to exist.
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const cli = process.env.FIREBASE_TOOLS_LIB || path.join(process.env.APPDATA || '', 'npm/node_modules/firebase-tools/lib');
const { getGlobalDefaultAccount } = require(path.join(cli, 'auth'));
const { requireAuth } = require(path.join(cli, 'requireAuth'));
const { Client } = require(path.join(cli, 'apiv2'));

async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--list-profiles')) {
    const account = getGlobalDefaultAccount();
    if (!account) throw new Error('Ejecuta firebase login primero.');
    await requireAuth({project:'boteparroquial', ...account, nonInteractive:true});
    const api = new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
    const response = await api.get('projects/boteparroquial/databases/(default)/documents/users', {queryParams:{pageSize:100}});
    console.log(JSON.stringify({profiles:(response.body.documents || []).map(doc => ({
      uid:doc.name.split('/').at(-1),name:doc.fields.displayName?.stringValue,email:doc.fields.email?.stringValue,
    })),hasMore:!!response.body.nextPageToken}));
    return;
  }
  if (args.some(arg => arg.startsWith('--') && !['--name','--apply','--owner-uid'].includes(arg)) ||
      args.filter(arg => arg === '--name').length !== 1) {
    throw new Error('Uso: node tools/bootstrap_group.cjs --name NOMBRE [--apply]');
  }
  const name = args[args.indexOf('--name') + 1]?.trim();
  if (!name || name.startsWith('--') || name.length > 120) throw new Error('Nombre obligatorio, máximo 120 caracteres.');
  const project = 'boteparroquial';
  const account = getGlobalDefaultAccount();
  if (!account?.user?.email) throw new Error('Ejecuta firebase login primero.');
  await requireAuth({project, ...account, nonInteractive: true});
  const api = new Client({urlPrefix:'https://firestore.googleapis.com', apiVersion:'v1'});
  const database = `projects/${project}/databases/(default)`;
  const documents = `${database}/documents`;
  const query = async (collection, field, value) => {
    const response = await api.post(`${documents}:runQuery`, {structuredQuery:{
      from:[{collectionId:collection}],
      where:{fieldFilter:{field:{fieldPath:field},op:'EQUAL',value:{stringValue:value}}},
    }});
    return response.body.filter(row => row.document).map(row => row.document);
  };
  const requestedUid = args.includes('--owner-uid') ? args[args.indexOf('--owner-uid') + 1] : null;
  if (requestedUid && !/^[A-Za-z0-9_-]{1,128}$/.test(requestedUid)) throw new Error('UID no válido.');
  const profiles = requestedUid
    ? [(await api.get(`${documents}/users/${requestedUid}`)).body]
    : await query('users','email',account.user.email);
  if (profiles.length !== 1) throw new Error('No hay un único perfil de la app con el correo de Firebase CLI. No se asignará ningún propietario.');
  const profile = profiles[0];
  const uid = profile.name.split('/').at(-1);
  const displayName = profile.fields.displayName?.stringValue;
  const ownerEmail = profile.fields.email?.stringValue;
  if (!displayName) throw new Error('El perfil debe tener nombre.');
  const existing = (await query('groups','createdBy',uid)).filter(doc => doc.fields.name?.stringValue === name);
  if (existing.length) {
    if (existing.length !== 1) throw new Error('Hay varios grupos con este nombre y creador; revisión manual necesaria.');
    const groupId = existing[0].name.split('/').at(-1);
    const member = (await api.get(`${documents}/groups/${groupId}/members/${encodeURIComponent(uid)}`)).body;
    if (member.fields.uid?.stringValue !== uid || member.fields.role?.stringValue !== 'owner' || member.fields.status?.stringValue !== 'active') {
      throw new Error('El grupo ya existe con una membresía diferente. No se modificará.');
    }
    console.log(JSON.stringify({status:'already-exists',project,groupId,name,ownerEmail,ownerUid:uid}));
    return;
  }
  const groupId = randomUUID();
  const plan = {project,groupId,name,ownerEmail,ownerUid:uid,displayName,currency:'EUR',timeZone:'Europe/Madrid'};
  if (!args.includes('--apply')) { console.log(JSON.stringify({status:'dry-run',...plan})); return; }
  const str = value => ({stringValue:value});
  const write = (suffix, fields, timestamps) => ({
    update:{name:`${documents}/${suffix}`,fields}, currentDocument:{exists:false},
    updateTransforms:timestamps.map(fieldPath => ({fieldPath,setToServerValue:'REQUEST_TIME'})),
  });
  await api.post(`${documents}:commit`, {writes:[
    write(`groups/${groupId}`,{name:str(name),currency:str('EUR'),timeZone:str('Europe/Madrid'),
      isActive:{booleanValue:true},createdBy:str(uid)},['createdAt','updatedAt']),
    write(`groups/${groupId}/members/${uid}`,{uid:str(uid),displayName:str(displayName),
      role:str('owner'),status:str('active')},['joinedAt','updatedAt']),
  ]});
  console.log(JSON.stringify({status:'created',...plan}));
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
