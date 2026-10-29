// Operator reads only. This does not certify physical delivery or client roles.
const path=require('node:path');
const cli=path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount}=require(path.join(cli,'auth'));
const {requireAuth}=require(path.join(cli,'requireAuth'));
const {Client}=require(path.join(cli,'apiv2'));
(async()=>{
  await requireAuth({project:'boteparroquial',...getGlobalDefaultAccount(),nonInteractive:true});
  const api=new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  const root='projects/boteparroquial/databases/(default)/documents/groups/demo-notifications-20261020';
  const docs=(await api.get(`${root}/notifications`,{skipLog:{resBody:true}})).body.documents||[];
  if(docs.length!==1||docs[0].fields.kind.stringValue!=='joinRequested'||docs[0].fields.recipientUid.stringValue!=='JDQpjp5XtFTDOoVgK5Rbc9EGUHB2')throw new Error('Unexpected inbox result');
  const deliveries=(await api.get(`${root}/notificationDeliveries`,{skipLog:{resBody:true}})).body.documents||[];
  if(deliveries.length!==0)throw new Error('Suppressed push unexpectedly attempted');
  console.log(JSON.stringify({groupId:'demo-notifications-20261020',inboxCount:1,kind:'joinRequested',recipientVerified:true,pushAttempts:0,financialWrites:0,physicalDeliveryTested:false}));
})().catch(()=>{console.error('La validación de bandeja DEMO no coincide con lo esperado.');process.exitCode=1;});
