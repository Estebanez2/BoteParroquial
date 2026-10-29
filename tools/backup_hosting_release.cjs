// Read-only operator snapshot; no publication, credentials or Firebase data.
const fs = require('node:fs/promises');
const path = require('node:path');
const cli = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount} = require(path.join(cli, 'auth'));
const {requireAuth} = require(path.join(cli, 'requireAuth'));
const {Client} = require(path.join(cli, 'apiv2'));
(async () => {
  const directory = process.argv[2];
  if (!directory || !path.isAbsolute(directory)) throw new Error('Se necesita la carpeta absoluta del respaldo verificado.');
  const manifest = JSON.parse(await fs.readFile(path.join(directory, 'manifest.json'), 'utf8'));
  if (manifest.project !== 'boteparroquial' || !manifest.verifiedAgainstActiveRelease) throw new Error('Respaldo no verificado.');
  await requireAuth({project:'boteparroquial', ...getGlobalDefaultAccount(), nonInteractive:true});
  const api = new Client({urlPrefix:'https://firebasehosting.googleapis.com', apiVersion:'v1beta1'});
  const result = (await api.get('sites/boteparroquial/releases?pageSize=1', {skipLog:{resBody:true}})).body;
  await fs.writeFile(path.join(directory,'hosting-release-before.json'), JSON.stringify({fetchedAt:new Date().toISOString(), ...result}, null, 2), {flag:'wx'});
  console.log(JSON.stringify({site:'boteparroquial',previousRelease:result.releases?.[0]?.name || null,previousVersion:result.releases?.[0]?.version?.name || null,backup:directory}));
})().catch(() => {console.error('No se pudo guardar la referencia de Hosting; no se ha publicado.');process.exitCode=1;});
