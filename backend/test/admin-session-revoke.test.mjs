import test, { afterEach } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.mjs';

const PROJECT = 'contentnex-admin';
const originalFetch = globalThis.fetch;
const cryptoApi = globalThis.crypto;
const keyPair = await cryptoApi.subtle.generateKey(
  { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
  true,
  ['sign', 'verify'],
);
const publicJwk = await cryptoApi.subtle.exportKey('jwk', keyPair.publicKey);
publicJwk.kid = 'contentnex-revoke-test-key';

afterEach(() => { globalThis.fetch = originalFetch; });

function base64url(value) { return Buffer.from(value).toString('base64url'); }

async function createToken(role = 'super_admin') {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT', kid: publicJwk.kid };
  const claims = {
    iss: `https://securetoken.google.com/${PROJECT}`,
    aud: PROJECT,
    sub: 'acting-super-admin',
    iat: now,
    exp: now + 3600,
    auth_time: now - 10,
    email: 'admin@example.test',
    email_verified: true,
    contentnexRole: role,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const signature = await cryptoApi.subtle.sign('RSASSA-PKCS1-v1_5', keyPair.privateKey, new TextEncoder().encode(unsigned));
  return `${unsigned}.${base64url(new Uint8Array(signature))}`;
}

function installJwks() {
  globalThis.fetch = async (url) => {
    assert.equal(String(url), 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
    return { ok: true, json: async () => ({ keys: [publicJwk] }) };
  };
}

function makeEnv({ failWrite = false } = {}) {
  const writes = [];
  return {
    writes,
    env: {
      ADMIN_FIREBASE_PROJECT_ID: PROJECT,
      ADMIN_DB: {
        prepare(sql) {
          return {
            all: async () => ({ results: [
              { uid: 'bootstrap-admin-uid', role: 'super_admin', status: 'active', created_at: 1700000000 },
            ] }),
            bind(...values) {
              return {
                first: async () => {
                  if (!sql.includes('FROM admin_users WHERE uid = ?')) return null;
                  return values[0] === 'acting-super-admin'
                    ? { uid: 'acting-super-admin', role: 'super_admin', status: 'active' }
                    : { uid: 'target-admin-uid', role: 'admin', status: 'active' };
                },
                run: async () => {
                  writes.push({ sql, values });
                  if (failWrite) throw new Error('simulated D1 failure');
                  return { success: true };
                },
              };
            },
          };
        },
      },
    },
  };
}

async function listUsers(token, env) {
  return worker.fetch(new Request('https://contentnex-api.test/v1/admin/users', {
    headers: { Authorization: `Bearer ${token}` },
  }), env);
}

async function revoke(token, env, body = { uid: 'target-admin-uid' }) {
  return worker.fetch(new Request('https://contentnex-api.test/v1/admin/sessions/revoke', {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }), env);
}

test('super_admin can revoke a target session and the action is audited', async () => {
  installJwks();
  const token = await createToken();
  const { env, writes } = makeEnv();
  const response = await revoke(token, env);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.revoked, true);
  assert.equal(body.targetUid, 'target-admin-uid');
  assert.match(writes[0].sql, /INSERT INTO admin_token_revocations/);
  assert.deepEqual(writes[0].values, ['target-admin-uid', body.revokedAfter, body.revokedAfter]);
  assert.match(writes[1].sql, /INSERT INTO admin_audit_logs/);
  assert.equal(writes[1].values[2], 'admin.session.revoke');
  assert.equal(writes[1].values[5], 'success');
  assert.deepEqual(JSON.parse(writes[1].values[6]), {
    targetUid: 'target-admin-uid',
    revokedAfter: body.revokedAfter,
  });
});

test('non-super_admin cannot revoke a session', async () => {
  installJwks();
  const token = await createToken('support');
  const { env, writes } = makeEnv();
  const response = await revoke(token, env);

  assert.equal(response.status, 403);
  assert.equal((await response.json()).error.code, 'FORBIDDEN');
  assert.equal(writes.length, 1);
  assert.match(writes[0].sql, /INSERT INTO admin_audit_logs/);
  assert.equal(writes[0].values[5], 'denied');
});

test('invalid target UID is rejected without database writes', async () => {
  installJwks();
  const token = await createToken();
  const { env, writes } = makeEnv();
  const response = await revoke(token, env, { uid: '   ' });

  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, 'INVALID_TARGET_UID');
  assert.equal(writes.length, 0);
});

test('revocation endpoint fails closed when D1 write fails', async () => {
  installJwks();
  const token = await createToken();
  const { env } = makeEnv({ failWrite: true });
  const response = await revoke(token, env);

  assert.equal(response.status, 503);
  assert.equal((await response.json()).error.code, 'ADMIN_SESSION_REVOKE_FAILED');
});

test('super_admin can read the registered admin directory and the read is audited', async () => {
  installJwks();
  const token = await createToken();
  const { env, writes } = makeEnv();
  const response = await listUsers(token, env);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.items.length, 1);
  assert.equal(body.items[0].uid, 'bootstrap-admin-uid');
  assert.equal(body.items[0].role, 'super_admin');
  assert.equal(body.items[0].status, 'active');
  assert.match(writes[0].sql, /INSERT INTO admin_audit_logs/);
  assert.equal(writes[0].values[2], 'admin.users.read');
});

test('unregistered UID cannot be used to revoke an admin session', async () => {
  installJwks();
  const token = await createToken();
  const { env, writes } = makeEnv();
  env.ADMIN_DB.prepare = (sql) => ({
    bind(...values) {
      return {
        first: async () => sql.includes('FROM admin_users WHERE uid = ?') && values[0] === 'acting-super-admin'
          ? { uid: 'acting-super-admin', role: 'super_admin', status: 'active' }
          : null,
        run: async () => { writes.push({ sql, values }); return { success: true }; },
        all: async () => ({ results: [] }),
      };
    },
  });
  const response = await revoke(token, env);
  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, 'TARGET_ADMIN_NOT_FOUND');
  assert.equal(writes.length, 1);
  assert.equal(writes[0].values[5], 'denied');
});

test('super_admin cannot revoke their own session from the directory screen', async () => {
  installJwks();
  const token = await createToken();
  const { env, writes } = makeEnv();
  const response = await revoke(token, env, { uid: 'acting-super-admin' });
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error.code, 'SELF_REVOCATION_NOT_ALLOWED');
  assert.equal(writes.length, 0);
});

test('admin operations reject a super_admin token absent from the admin directory', async () => {
  installJwks();
  const token = await createToken();
  const { env } = makeEnv();
  env.ADMIN_DB.prepare = (sql) => ({
    bind(...values) {
      return {
        first: async () => sql.includes('FROM admin_users WHERE uid = ?') ? null : null,
        run: async () => ({ success: true }),
      };
    },
    all: async () => ({ results: [] }),
  });
  const response = await listUsers(token, env);
  assert.equal(response.status, 403);
  assert.equal((await response.json()).error.code, 'FORBIDDEN');
});
