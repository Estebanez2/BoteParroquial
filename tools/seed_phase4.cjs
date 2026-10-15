// Test fixtures explicitly authorized by the user. Creates missing docs only; never deletes/overwrites.
const path=require('node:path');
const fs=require('node:fs');
const cli=process.env.FIREBASE_TOOLS_LIB || path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib');
const {getGlobalDefaultAccount}=require(path.join(cli,'auth'));
const {requireAuth}=require(path.join(cli,'requireAuth'));
const {Client}=require(path.join(cli,'apiv2'));
async function main(){
  const args=process.argv.slice(2),groupId=args[args.indexOf('--group')+1];
  if(!args.includes('--group')||!/^[A-Za-z0-9_-]{1,128}$/.test(groupId||''))throw new Error('Uso: node tools/seed_phase4.cjs --group ID [--apply]');
  await requireAuth({project:'boteparroquial',...getGlobalDefaultAccount(),nonInteractive:true});
  const api=new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  const root='projects/boteparroquial/databases/(default)/documents';
  const source=(await api.get(`${root}/groups/${groupId}`)).body;
  const uid=source.fields.createdBy.stringValue;
  const owner=(await api.get(`${root}/groups/${groupId}/members/${uid}`)).body.fields;
  if(owner.role.stringValue!=='owner'||owner.status.stringValue!=='active'||source.fields.isActive.booleanValue!==true)throw new Error('El grupo debe tener owner activo.');
  const encode=value=>value===null?{nullValue:null}:typeof value==='boolean'?{booleanValue:value}:typeof value==='number'?{integerValue:String(value)}:{stringValue:value};
  const writes=[];
  const add=(suffix,fields,times=['createdAt','updatedAt'])=>writes.push({update:{name:`${root}/${suffix}`,fields:Object.fromEntries(Object.entries(fields).map(([key,value])=>[key,encode(value)]))},
    currentDocument:{exists:false},updateTransforms:times.map(fieldPath=>({fieldPath,setToServerValue:'REQUEST_TIME'}))});
  const person=(group,id,name,active)=>add(`groups/${group}/persons/${id}`,{displayName:`[Prueba] ${name}`,notes:'DEMO Phase 4: datos ficticios autorizados.',isActive:active,createdBy:uid,updatedBy:uid});
  const negative=`demo4-${groupId}-negative`,empty=`demo4-${groupId}-empty`;
  for(const [id,name]of[[negative,'Prueba · Saldo negativo'],[empty,'Prueba · Historial vacío']]){
    add(`groups/${id}`,{name,currency:'EUR',timeZone:'Europe/Madrid',isActive:true,createdBy:uid,description:'DEMO Phase 4: grupo de prueba.'});
    add(`groups/${id}/members/${uid}`,{uid,displayName:owner.displayName.stringValue,role:'owner',status:'active'},['joinedAt','updatedAt']);
  }
  person(groupId,'demo4-ana','Ana',true);person(groupId,'demo4-luis','Luis',true);person(groupId,'demo4-marta','Marta (inactiva)',false);
  person(negative,'demo4-ana','Ana',true);
  const movement=(group,id,type,amount,personId,description,extra={},times=[])=>{
    add(`groups/${group}/movements/${id}`,{type,amountCents:amount,status:'active',personId,description:`DEMO: ${description}`,createdBy:uid,...extra},['createdAt','updatedAt',...times]);
    writes.at(-1).update.fields.occurredAt={timestampValue:'2026-10-15T00:00:00Z'};
  };
  movement(groupId,'demo4-income','income',2050,'demo4-ana','Ingreso con céntimos');
  movement(groupId,'demo4-late','income',3500,'demo4-marta','Ingreso de persona inactiva');
  writes.at(-1).update.fields.occurredAt={timestampValue:'2026-08-10T00:00:00Z'};
  movement(groupId,'demo4-general','withdrawal',1500,null,'Compra de material del grupo');
  movement(groupId,'demo4-person','withdrawal',750,'demo4-luis','Devolución a una persona');
  movement(groupId,'demo4-cancelled','income',1000,'demo4-ana','Ingreso anulado',{status:'cancelled',cancelledBy:uid,cancellationReason:'DEMO: ingreso duplicado'},['cancelledAt']);
  movement(groupId,'demo4-original','income',5000,'demo4-ana','Importe original conservado',{
    status:'corrected',correctedBy:uid,correctionReason:'DEMO: el importe correcto era 25 €',correctedByMovementId:'demo4-replacement'},['correctedAt']);
  movement(groupId,'demo4-replacement','income',2500,'demo4-ana','Sustituto del ingreso corregido',{correctionOfMovementId:'demo4-original'});
  movement(negative,'demo4-income','income',1000,'demo4-ana','Ingreso inicial');
  movement(negative,'demo4-withdrawal','withdrawal',2500,null,'Retirada superior al fondo');
  const existing=await Promise.all(writes.map(async write=>{try{await api.get(write.update.name);return true;}catch(error){if(error.status===404||error.context?.response?.statusCode===404)return false;throw error;}}));
  const missing=writes.filter((_,index)=>!existing[index]);
  const report={project:'boteparroquial',primaryGroupId:groupId,negativeGroupId:negative,emptyGroupId:empty,
    planned:missing.length,skipped:existing.filter(Boolean).length,applied:args.includes('--apply')};
  if(args.includes('--apply')&&missing.length)await api.post(`${root}:commit`,{writes:missing});
  if(args.includes('--verify')) {
    report.ledgers=[];
    for(const id of [groupId,negative,empty]) {
      const response=await api.post(`${root}/groups/${id}:runQuery`,{structuredQuery:{from:[{collectionId:'movements'}]}});
      const docs=response.body.filter(row=>row.document).map(row=>row.document);
      let balance=0n;
      const states={active:0,cancelled:0,corrected:0};
      const byId=new Map(docs.map(doc=>[doc.name.split('/').at(-1),doc.fields]));
      for(const doc of docs) {
        const d=doc.fields,id=doc.name.split('/').at(-1),state=d.status.stringValue;
        if(!d.amountCents.integerValue||!(state in states))throw new Error('Importe o estado inválido.');
        states[state]++;
        if(state==='active')balance+=(d.type.stringValue==='income'?1n:-1n)*BigInt(d.amountCents.integerValue);
        if(state==='corrected'&&byId.get(d.correctedByMovementId.stringValue)?.correctionOfMovementId?.stringValue!==id)throw new Error('Corrección no recíproca.');
        if(d.correctionOfMovementId&&byId.get(d.correctionOfMovementId.stringValue)?.correctedByMovementId?.stringValue!==id)throw new Error('Sustituto huérfano.');
      }
      report.ledgers.push({groupId:id,movements:docs.length,...states,balanceCents:balance.toString()});
    }
  }
  fs.mkdirSync('.dart_tool',{recursive:true});fs.writeFileSync('.dart_tool/phase4-fixtures.json',JSON.stringify(report,null,2));
  console.log(JSON.stringify(report));
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
