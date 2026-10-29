// Operator-only, read-only Firebase access. Never uploads or publishes rules.
// Uses the existing Firebase CLI login; no credentials are written to the backup.
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const {createHash} = require('node:crypto');
const cli = process.env.FIREBASE_TOOLS_LIB || path.join(process.env.APPDATA || '', 'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount} = require(path.join(cli, 'auth'));
const {requireAuth} = require(path.join(cli, 'requireAuth'));
const {Client} = require(path.join(cli, 'apiv2'));

async function main() {
  const args = process.argv.slice(2);
  if (args.length && (args.length !== 2 || args[0] !== '--output' || !path.isAbsolute(args[1]))) {
    throw new Error('Uso: node tools/backup_firestore_rules.cjs [--output RUTA_ABSOLUTA_NUEVA]');
  }
  const project = 'boteparroquial';
  const account = getGlobalDefaultAccount();
  if (!account) throw new Error('No hay sesión Firebase CLI. Ejecuta firebase.cmd login y vuelve a intentar.');
  await requireAuth({project, ...account, nonInteractive: true});
  const api = new Client({urlPrefix: 'https://firebaserules.googleapis.com', apiVersion: 'v1'});
  const releaseName = `projects/${project}/releases/cloud.firestore`;
  const release = (await api.get(releaseName)).body;
  if (typeof release.rulesetName !== 'string' || !release.rulesetName.startsWith(`projects/${project}/rulesets/`)) {
    throw new Error('La publicación activa no identifica un ruleset del proyecto esperado.');
  }
  const ruleset = (await api.get(release.rulesetName, {skipLog: {resBody: true}})).body;
  const files = ruleset.source?.files;
  if (!Array.isArray(files) || files.length !== 1 || typeof files[0].content !== 'string' || !files[0].content.trim()) {
    throw new Error('Se esperaba un único archivo de reglas publicado; no se ha creado una copia incompleta.');
  }
  const current = (await api.get(releaseName)).body;
  if (current.rulesetName !== release.rulesetName) {
    throw new Error('La publicación ha cambiado durante la lectura. Vuelve a ejecutar la copia.');
  }
  const fetchedAt = new Date().toISOString();
  const directory = args[1] || path.join(os.homedir(), 'Documents', 'BoteParroquial-backups',
    'firestore-rules', fetchedAt.replace(/[:.]/g, '-'));
  await fs.mkdir(path.dirname(directory), {recursive: true});
  // Refuse an existing directory: backups are never overwritten.
  await fs.mkdir(directory);
  const content = files[0].content;
  const checksum = createHash('sha256').update(content, 'utf8').digest('hex');
  const rulesPath = path.join(directory, 'firestore.rules');
  await fs.writeFile(rulesPath, content, {encoding: 'utf8', flag: 'wx'});
  const saved = await fs.readFile(rulesPath);
  if (createHash('sha256').update(saved).digest('hex') !== checksum) {
    throw new Error('El archivo guardado no coincide con la fuente publicada. No utilizar esta copia.');
  }
  const manifest = {project, database: '(default)', fetchedAt, releaseName, rulesetName: release.rulesetName,
    releaseUpdateTime: release.updateTime || null, rulesetCreateTime: ruleset.createTime || null,
    sourceFileName: files[0].name, sha256: checksum, byteLength: saved.length,
    verifiedAgainstActiveRelease: true, containsCredentials: false};
  await fs.writeFile(path.join(directory, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n', {flag: 'wx'});
  await fs.writeFile(path.join(directory, 'firebase.rollback.json'), JSON.stringify({
    firestore: {database: '(default)', rules: 'firestore.rules'},
  }, null, 2) + '\n', {flag: 'wx'});
  const command = `firebase.cmd deploy --only firestore:rules --project ${project} --config "${path.join(directory, 'firebase.rollback.json')}" --non-interactive`;
  const instructions = [
    '# Copia de las reglas publicadas de Firestore', '',
    `Proyecto: ${project}. Base: (default). Descarga UTC: ${fetchedAt}.`,
    `Ruleset: ${release.rulesetName}. SHA-256: ${checksum}.`, '',
    'Esta copia procede de la publicación remota activa, no del archivo modificado del repositorio.',
    'Se comprobó la publicación antes/después de descargar y el hash del archivo guardado.',
    'No contiene tokens ni credenciales. Se guarda fuera del repositorio por defecto.', '',
    '## Restaurar solo las reglas', '',
    'Requiere Firebase CLI instalado, sesión autorizada y aprobación de la restauración.',
    'Ejecutar únicamente cuando se quiera volver a esta versión de permisos:', '',
    '```powershell', command, '```', '',
    'El comando publica exclusivamente las reglas de esta copia, sin sobrescribir firestore.rules del proyecto.',
    'No se ha ejecutado como parte de la copia. No revierte documentos, índices, usuarios ni archivos de fotos.',
    'Datos creados con una app posterior permanecen; algunas funciones podrían dejar de tener permiso.',
    'No es una copia de la base de datos. Revisar compatibilidad de la app antes de restaurar.', '',
  ].join('\n');
  await fs.writeFile(path.join(directory, 'RESTORE.md'), instructions, {encoding: 'utf8', flag: 'wx'});
  console.log(JSON.stringify({directory, ...manifest}));
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
