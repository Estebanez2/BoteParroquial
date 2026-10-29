const {test} = require('node:test');
const assert = require('node:assert/strict');
const {snapshot, ROOT} = require('./backup_firestore_data.cjs');
test('Snapshot único, paginación y subcolecciones de padres ausentes sin perder int64', async()=>{
  const stamp='2026-10-20T12:00:00.123456Z', times=[];
  const data=await snapshot({
    readTime:async()=>stamp,
    collections:async(parent,time)=>{times.push(time);return{collectionIds:parent===ROOT?['groups']:parent===`${ROOT}/groups/missing`?['movements']:[]};},
    documents:async(collection,time,token)=>{times.push(time);return collection.endsWith('/movements')?
      {documents:[{name:`${collection}/one`,fields:{amountCents:{integerValue:'9007199254740993'}},updateTime:stamp}]}:
      token?{documents:[{name:`${collection}/missing`}]}:{documents:[{name:`${collection}/present`,fields:{},updateTime:stamp}],nextPageToken:'next'};},
  });
  assert.equal(data.documents.length,2);assert.equal(data.missingDocuments.length,1);
  assert.equal(data.documents[0].fields.amountCents.integerValue,'9007199254740993');
  assert.ok(times.every(time=>time===stamp));
});
test('No produce una copia válida si falla una página o se repite la paginación', async()=>{
  await assert.rejects(snapshot({readTime:async()=>new Date().toISOString(),collections:async()=>({collectionIds:[],nextPageToken:'same'})}));
});
