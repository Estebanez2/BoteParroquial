// Operator-only. Creates the one inbox index; never deletes/changes other indexes.
const path = require('node:path');
const cli = process.env.FIREBASE_TOOLS_LIB || path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount} = require(path.join(cli, 'auth'));
const {requireAuth} = require(path.join(cli, 'requireAuth'));
const {Client} = require(path.join(cli, 'apiv2'));
(async () => {
  const args = process.argv.slice(2);
  if (args.length && (args.length !== 1 || args[0] !== '--apply')) throw new Error('Use --apply to create only the inbox index.');
  const project = 'boteparroquial', account = getGlobalDefaultAccount();
  if (!account) throw new Error('Firebase CLI login required.');
  await requireAuth({project, ...account, nonInteractive:true});
  const api = new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  const parent = `projects/${project}/databases/(default)/collectionGroups/notifications/indexes`;
  const indexes = [];
  let pageToken;
  do {
    const response = await api.get(parent, {queryParams:pageToken ? {pageToken} : {},skipLog:{resBody:true}});
    indexes.push(...(response.body.indexes || []));
    pageToken = response.body.nextPageToken;
  } while(pageToken);
  const fields = [{fieldPath:'recipientUid',order:'ASCENDING'},{fieldPath:'createdAt',order:'DESCENDING'}];
  const match = indexes.find(index => index.queryScope === 'COLLECTION' &&
    JSON.stringify(index.fields.filter(field => field.fieldPath !== '__name__')) === JSON.stringify(fields));
  if(match) { console.log(JSON.stringify({status:'existing',name:match.name,state:match.state})); return; }
  if(!args.includes('--apply')) { console.log(JSON.stringify({status:'plan',project,collectionGroup:'notifications',queryScope:'COLLECTION',fields,otherIndexesUntouched:true})); return; }
  const response = await api.post(parent,{queryScope:'COLLECTION',fields},{skipLog:{reqBody:true,resBody:true}});
  console.log(JSON.stringify({status:'creating',operation:response.body.name,index:response.body.metadata?.index}));
})().catch(error => {console.error(error.message);process.exitCode=1;});
