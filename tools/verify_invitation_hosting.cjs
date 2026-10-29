const fs = require('node:fs');
const assert = require('node:assert/strict');
(async () => {
  const base = 'https://boteparroquial.web.app';
  const assets = await fetch(`${base}/.well-known/assetlinks.json`, {redirect:'error'});
  assert.equal(assets.status, 200);
  assert.match(assets.headers.get('content-type'), /application\/json/);
  assert.deepEqual(await assets.json(), JSON.parse(fs.readFileSync('hosting/public/.well-known/assetlinks.json','utf8')));
  const page = await fetch(`${base}/join/DEMO.12345678901234567890123456789012`, {redirect:'error'});
  assert.equal(page.status, 200);
  assert.equal(page.headers.get('referrer-policy'), 'no-referrer');
  assert.match(page.headers.get('content-security-policy'), /default-src 'none'/);
  assert.match(await page.text(), /invitation.js/);
  console.log(JSON.stringify({host:'boteparroquial.web.app',assetLinksVerified:true,invitationFallbackHttp:200,referrerPolicy:'no-referrer',physicalAppLinkTested:false}));
})().catch(() => {console.error('La comprobación HTTP pública de invitaciones no coincide con lo esperado.');process.exitCode=1;});
