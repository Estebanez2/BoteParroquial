// Read-only operator comparison of REST aggregates with one coherent snapshot.
const {firebaseClient,ROOT,route}=require('./backup_firestore_data.cjs');
async function main(){
  const api=await firebaseClient(),quiet={skipLog:{body:true,resBody:true}},now=new Date(),start=new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth())),end=new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth()+1));
  const initial=(await api.post(`${route(ROOT)}:runQuery`,{structuredQuery:{from:[{collectionId:'groups'}]}},quiet)).body;
  const readTime=initial.at(-1).readTime,groups=initial.filter(r=>r.document?.fields.isActive?.booleanValue===true).map(r=>r.document);
  const data={readTime,documents:[]};
  for(const group of groups){
    const rows=(await api.post(`${route(group.name)}:runQuery`,{readTime,structuredQuery:{from:[{collectionId:'movements'}]}},quiet)).body;
    data.documents.push(...rows.filter(r=>r.document).map(r=>r.document));
  }
  let queries=0;
  for(const group of groups)for(const type of ['income','withdrawal'])for(const month of [false,true]){
    const condition=(fieldPath,op,value)=>({fieldFilter:{field:{fieldPath},op,value}});
    const filters=[condition('status','EQUAL',{stringValue:'active'}),condition('type','EQUAL',{stringValue:type}),...(month?[condition('occurredAt','GREATER_THAN_OR_EQUAL',{timestampValue:start.toISOString()}),condition('occurredAt','LESS_THAN',{timestampValue:end.toISOString()})]:[])];
    const body={readTime:data.readTime,structuredAggregationQuery:{structuredQuery:{from:[{collectionId:'movements'}],where:{compositeFilter:{op:'AND',filters}}},aggregations:[{alias:'total',sum:{field:{fieldPath:'amountCents'}}}]}};
    const response=(await api.post(`${route(group.name)}:runAggregationQuery`,body,{skipLog:{body:true,resBody:true}})).body;
    const result=response.filter(r=>r.result)[0]?.result.aggregateFields?.total;
    const expected=data.documents.filter(d=>d.name.startsWith(`${group.name}/movements/`)&&d.fields.status?.stringValue==='active'&&d.fields.type?.stringValue===type&&(!month||(Date.parse(d.fields.occurredAt.timestampValue)>=start&&Date.parse(d.fields.occurredAt.timestampValue)<end))).reduce((total,d)=>total+BigInt(d.fields.amountCents.integerValue),0n);
    if(typeof result?.integerValue!=='string'||BigInt(result.integerValue)!==expected)throw new Error('cash_aggregate_mismatch');
    queries++;
  }
  console.log(JSON.stringify({project:'boteparroquial',groups:groups.length,queries,matched:true,readTime:data.readTime,remoteWrites:0}));
}
main().catch(error=>{const body=error.context?.body;console.error(JSON.stringify({error:'cash_verification_failed',status:error.status??null,details:Array.isArray(body)?body.map(r=>r.error):body?.error??null}));process.exitCode=1;});
