// Read-only comparison of the active release against the local rules file.
const path = require('node:path');
const fs = require('node:fs');
const {createHash} = require('node:crypto');
const cli = process.env.FIREBASE_TOOLS_LIB || path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount} = require(path.join(cli, 'auth'));
const {requireAuth} = require(path.join(cli, 'requireAuth'));
const {Client} = require(path.join(cli, 'apiv2'));
async function main() {
  const project = 'boteparroquial', account = getGlobalDefaultAccount();
  if (!account) throw new Error('Se necesita la sesión autorizada de Firebase CLI.');
  await requireAuth({project, ...account, nonInteractive: true});
  const api = new Client({urlPrefix: 'https://firebaserules.googleapis.com', apiVersion: 'v1'});
  const release = (await api.get(`projects/${project}/releases/cloud.firestore`)).body;
  const rules = (await api.get(release.rulesetName, {skipLog: {resBody: true}})).body;
  const files = rules.source?.files;
  if (files?.length !== 1 || typeof files[0].content !== 'string') throw new Error('La publicación no contiene un único archivo de reglas.');
  const hash = value => createHash('sha256').update(value).digest('hex');
  const remoteHash = hash(files[0].content), localHash = hash(fs.readFileSync(path.join(__dirname, '../firestore.rules')));
  console.log(JSON.stringify({project, rulesetName: release.rulesetName, releaseUpdateTime: release.updateTime,
    remoteSha256: remoteHash, localSha256: localHash, matchesLocal: remoteHash === localHash}));
  if (remoteHash !== localHash) process.exitCode = 1;
}
main().catch(error => {console.error(error.message); process.exitCode = 1;});
