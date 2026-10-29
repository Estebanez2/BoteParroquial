// One-off operator recovery copy before an explicitly authorized reset.
// No scheduler, credential export, writes to Firestore or automatic restoration.
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const {createHash} = require('node:crypto');
const PROJECT = 'boteparroquial';
const ROOT = `projects/${PROJECT}/databases/(default)/documents`;
const route = name => name.split('/').map(encodeURIComponent).join('/');

async function snapshot(adapter) {
  const readTime = await adapter.readTime();
  if (typeof readTime !== 'string' || !Number.isFinite(Date.parse(readTime))) throw new Error('invalid_read_time');
  const documents = [], missingDocuments = [], visited = new Set();
  async function walk(parent) {
    if (visited.has(parent)) throw new Error('duplicate_document');
    visited.add(parent);
    let token;
    const collectionIds = new Set();
    const seenCatalogTokens = new Set();
    do {
      const page = await adapter.collections(parent, readTime, token);
      for (const id of page.collectionIds || []) {
        if (typeof id !== 'string' || !id || id.includes('/') || collectionIds.has(id)) throw new Error('invalid_catalog');
        collectionIds.add(id);
      }
      const next = page.nextPageToken;
      if (next && seenCatalogTokens.has(next)) throw new Error('repeated_page');
      if (next) seenCatalogTokens.add(next);
      token = next;
    } while (token);
    for (const id of [...collectionIds].sort()) {
      let pageToken;
      const seenTokens = new Set();
      do {
        const page = await adapter.documents(`${parent}/${id}`, readTime, pageToken);
        for (const doc of page.documents || []) {
          if (typeof doc.name !== 'string' || !doc.name.startsWith(`${parent}/${id}/`) ||
              !doc.name.slice(parent.length + id.length + 2) ||
              doc.name.slice(parent.length + id.length + 2).includes('/')) throw new Error('invalid_document_scope');
          if (doc.updateTime) {
            documents.push(doc); // Preserve Firestore Value wrappers, int64 strings and nanoseconds.
          } else {
            missingDocuments.push(doc.name);
          }
          await walk(doc.name); // Includes subcollections below a missing parent.
        }
        pageToken = page.nextPageToken;
        if (pageToken && seenTokens.has(pageToken)) throw new Error('repeated_page');
        if (pageToken) seenTokens.add(pageToken);
      } while (pageToken);
    }
  }
  await walk(ROOT);
  return {format:'boteparroquial.firestore-backup/v1', project:PROJECT, database:'(default)', readTime,
    documents:documents.sort((a,b)=>a.name.localeCompare(b.name)), missingDocuments:missingDocuments.sort()};
}
async function firebaseClient() {
  const cli = process.env.FIREBASE_TOOLS_LIB || path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
  const {getGlobalDefaultAccount} = require(path.join(cli, 'auth'));
  const {requireAuth} = require(path.join(cli, 'requireAuth'));
  const {Client} = require(path.join(cli, 'apiv2'));
  const account = getGlobalDefaultAccount();
  if (!account) throw new Error('firebase_login_required');
  await requireAuth({project:PROJECT, ...account, nonInteractive:true});
  return new Client({urlPrefix:'https://firestore.googleapis.com', apiVersion:'v1'});
}
function adapter(api) {
  const quiet = {body:true, resBody:true, queryParams:true};
  return {
    async readTime() {
      const body = (await api.post(`${route(ROOT)}:runQuery`, {structuredQuery:{from:[{collectionId:'groups'}], limit:1}}, {skipLog:quiet})).body;
      const time = body.at(-1)?.readTime;
      if (typeof time !== 'string') throw new Error('read_time_missing');
      return time;
    },
    async collections(parent, readTime, pageToken) {
      return (await api.post(`${route(parent)}:listCollectionIds`, {pageSize:300, readTime, ...(pageToken?{pageToken}:{})}, {skipLog:quiet})).body;
    },
    async documents(collection, readTime, pageToken) {
      return (await api.get(route(collection), {queryParams:{pageSize:300, showMissing:true, readTime, ...(pageToken?{pageToken}:{})}, skipLog:quiet})).body;
    },
  };
}
async function main() {
  const args = process.argv.slice(2);
  if (args.length && (args.length !== 2 || args[0] !== '--output' || !path.isAbsolute(args[1]))) throw new Error('invalid_output');
  const api = await firebaseClient();
  const data = await snapshot(adapter(api));
  const directory = args[1] || path.join(os.homedir(), 'Documents/BoteParroquial-backups/firestore-data', new Date().toISOString().replace(/[:.]/g,'-'));
  await fs.mkdir(path.dirname(directory), {recursive:true});
  await fs.mkdir(directory); // Never overwrite an existing copy.
  const bytes = Buffer.from(JSON.stringify(data));
  await fs.writeFile(path.join(directory,'firestore.json'), bytes, {flag:'wx',mode:0o600});
  const digest = buffer => createHash('sha256').update(buffer).digest('hex');
  const sha256 = digest(bytes);
  if (digest(await fs.readFile(path.join(directory,'firestore.json'))) !== sha256) throw new Error('backup_verification_failed');
  const counts = {};
  for (const doc of data.documents) {
    const collection = doc.name.slice(ROOT.length+1).split('/')[0];
    counts[collection] = (counts[collection]||0)+1;
  }
  const manifest = {format:data.format, project:PROJECT, readTime:data.readTime, completedAt:new Date().toISOString(),
    documents:data.documents.length, missingParents:data.missingDocuments.length, counts, sha256, bytes:bytes.length, verified:true,
    purpose:'one-off pre-reset recovery', includesPhotos:false, includesAuthAccounts:false, mayContainPrivateDeliveryTokens:true};
  await fs.writeFile(path.join(directory,'manifest.json'), JSON.stringify(manifest,null,2), {flag:'wx',mode:0o600});
  await fs.writeFile(path.join(directory,'README.txt'), 'Copia puntual anterior al reinicio, no copia semanal. firestore.json conserva los tipos REST y rutas exactos.\nNo incluye fotos, cuentas Auth, reglas ni configuración de Supabase. Contiene datos privados, incluidos registros de dispositivos si existían.\nUna restauración requiere autorización expresa y una herramienta que valide el manifiesto; no se restaura automáticamente.\n', {flag:'wx'});
  console.log(JSON.stringify({directory, ...manifest}));
}
module.exports = {snapshot, adapter, firebaseClient, ROOT, PROJECT, route};
if (require.main === module) main().catch(()=>{console.error('No se completó la copia puntual. No se han modificado datos remotos. Revisa la sesión Firebase y el destino.'); process.exitCode=1;});
