// Public configuration only; never read or print login credentials or user tokens.
const fs = require('node:fs');
const source = fs.readFileSync('lib/core/supabase/supabase_config.dart', 'utf8');
const base = source.match(/url = '([^']+)'/)[1];
const key = source.match(/'(sb_publishable_[^']+)'/)[1];
(async () => {
  for (const token of [null, 'invalid']) {
    const headers = { 'Content-Type': 'application/json', apikey: key };
    if (token) headers.Authorization = `Bearer ${token}`;
    const result = await fetch(`${base}/functions/v1/photo-access`, {
      method: 'POST', headers,
      body: JSON.stringify({ action: 'access', actorUid: 'probe', target: { kind: 'account', uid: 'probe' } }),
    });
    const text = await result.text();
    let body;
    try { body = JSON.parse(text); } catch {
      throw new Error(`Unexpected non-JSON response: ${result.status} (${text.slice(0, 100)})`);
    }
    if (result.status !== 401 || body.error !== 'unauthenticated') {
      throw new Error(`Unexpected status ${result.status}`);
    }
    console.log(`${token ? 'Invalid token' : 'No token'}: rejected (401)`);
  }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
