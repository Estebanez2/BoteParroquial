// Authorized DEMO fixtures: one isolated group, create-only atomic commit, no Auth accounts.
const path = require('node:path');
const {randomBytes} = require('node:crypto');
const cli = process.env.FIREBASE_TOOLS_LIB || path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount} = require(path.join(cli,'auth'));
const {requireAuth} = require(path.join(cli,'requireAuth'));
const {Client} = require(path.join(cli,'apiv2'));
const project = 'boteparroquial', groupId = 'demo7-invitations-20261017';
const sourceId = '786e41f1-7f03-48a5-b29a-db966b67cd56';
async function main() {
  const args = process.argv.slice(2);
  if (!args.includes('--apply') && !args.includes('--verify')) throw new Error('Uso: node tools/seed_phase7_invitations.cjs --apply | --verify');
  await requireAuth({project,...getGlobalDefaultAccount(),nonInteractive:true});
  const api = new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  const root = `projects/${project}/databases/(default)/documents`;
  if(args.includes('--apply')) {
    const source = (await api.get(`${root}/groups/${sourceId}`,{skipLog:{resBody:true}})).body.fields;
    const uid = source.createdBy.stringValue;
    const owner = (await api.get(`${root}/groups/${sourceId}/members/${uid}`,{skipLog:{resBody:true}})).body.fields;
    if(source.isActive.booleanValue !== true || owner.status.stringValue !== 'active' || owner.role.stringValue !== 'owner') throw new Error('El grupo de origen debe conservar su owner activo.');
    const secret = randomBytes(24).toString('base64url');
    const encode = value => value === null ? {nullValue:null} : typeof value === 'boolean' ? {booleanValue:value}
      : typeof value === 'number' ? {integerValue:String(value)} : typeof value === 'object'
      ? {mapValue:{fields:Object.fromEntries(Object.entries(value).map(([key,item]) => [key,encode(item)]))}} : {stringValue:value};
    const writes=[];
    function add(suffix,data,times=['createdAt','updatedAt']) {
      writes.push({update:{name:`${root}/groups/${groupId}${suffix ? `/${suffix}` : ''}`,
        fields:Object.fromEntries(Object.entries(data).map(([key,value])=>[key,encode(value)]))},currentDocument:{exists:false},
        updateTransforms:times.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))});
    }
    const name='[Prueba] Invitaciones DEMO',description='DEMO Phase 7. Las cuentas de ejemplo son ficticias; aprobarlas no crea usuarios Google.';
    add('',{name,description,currency:'EUR',timeZone:'Europe/Madrid',isActive:true,createdBy:uid,updatedBy:uid,lastAuditEventId:'created'});
    add(`members/${uid}`,{uid,displayName:owner.displayName.stringValue,role:'owner',status:'active',personId:'owner'},['joinedAt','updatedAt']);
    add('persons/owner',{displayName:owner.displayName.stringValue,notes:'DEMO: persona inicial del propietario.',isActive:true,createdBy:uid,updatedBy:uid});
    add('auditEvents/created',{action:'group.created',entityId:groupId,actorUid:uid,before:null,after:{name,description}},['createdAt']);
    add('invitationSettings/current',{code:secret,enabled:true,requiresApproval:true,updatedBy:uid,lastAuditEventId:'demo-invitation'},['updatedAt']);
    add(`invitations/${secret}`,{groupName:name,currency:'EUR',requiresApproval:true});
    add('auditEvents/demo-invitation',{action:'invitation.changed',entityType:'invitation',entityId:'current',actorUid:uid,before:null,
      after:{enabled:true,requiresApproval:true,regenerated:true}},['createdAt']);
    for(const [id,label] of [['demo7-pending-ana','[Prueba] Ana — solicitud ficticia'],['demo7-pending-luis','[Prueba] Luis — solicitud ficticia']]) {
      add(`joinRequests/${id}`,{uid:id,displayName:label,code:secret,status:'pending',reviewedBy:null,reviewedAt:null,lastAuditEventId:`request-${id}`});
      add(`auditEvents/request-${id}`,{action:'join.requested',entityType:'joinRequest',entityId:id,actorUid:id,before:null,
        after:{uid:id,displayName:label,status:'pending'}},['createdAt']);
    }
    const memberId='demo7-member-lucia',displayName='[Prueba] Lucía — miembro ficticio';
    add(`members/${memberId}`,{uid:memberId,displayName,role:'member',status:'active',personId:'demo7-person-lucia'},['joinedAt','updatedAt']);
    add('persons/demo7-person-lucia',{displayName,notes:'DEMO: su historial debe conservarse al retirar el acceso ficticio.',isActive:true,createdBy:uid,updatedBy:uid});
    add('movements/demo7-income',{type:'income',amountCents:2050,status:'active',description:'DEMO: ingreso histórico de Lucía.',personId:'demo7-person-lucia',createdBy:uid});
    writes.at(-1).update.fields.occurredAt={timestampValue:'2026-10-17T00:00:00Z'};
    await api.post(`${root}:commit`,{writes},{skipLog:{reqBody:true,resBody:true}});
    console.log(JSON.stringify({applied:true,groupId,createdDocuments:writes.length,overwrittenDocuments:0}));
  }
  if(args.includes('--verify')) {
    const group=(await api.get(`${root}/groups/${groupId}`,{skipLog:{resBody:true}})).body.fields;
    const lists={};
    for(const collectionId of ['members','persons','movements','joinRequests','auditEvents']) {
      const result=(await api.post(`${root}/groups/${groupId}:runQuery`,{structuredQuery:{from:[{collectionId}]}},{skipLog:{reqBody:true,resBody:true}})).body;
      lists[collectionId]=result.filter(row=>row.document).length;
    }
    console.log(JSON.stringify({verified:true,groupId,name:group.name.stringValue,...lists,
      note:'CLI privilegiada; no acredita login de las cuentas ficticias ni validación física.'}));
  }
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
