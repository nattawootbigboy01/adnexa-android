import test, { afterEach } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.mjs';

const ADMIN_PROJECT = 'contentnex-admin';
const originalFetch = globalThis.fetch;
const cryptoApi = globalThis.crypto;
const keyPair = await cryptoApi.subtle.generateKey(
  {
    name: 'RSASSA-PKCS1-v1_5',
    modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]),
    hash: 'SHA-256',
  },
  true,
  ['sign', 'verify'],
);
const publicJwk = await cryptoApi.subtle.exportKey('jwk', keyPair.publicKey);
publicJwk.kid = 'contentnex-audit-test-key';

afterEach(() => {
  globalThis.fetch = originalFetch;
});

function base64url(value) {
  return Buffer.from(value).toString('base64url');
}

async function createIdToken(overrides = {}) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT', kid: publicJwk.kid };
  const claims = {
    iss: `https://securetoken.google.com/${ADMIN_PROJECT}`,
    aud: ADMIN_PROJECT,
    sub: 'audit-test-admin-uid',
    iat: now,
    exp: now + 3600,
    auth_time: now - 30,
    email: 'admin@example.test',
    email_verified: true,
    contentnexRole: 'super_admin',
    ...overrides,
  };
  const unsigned = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(claims))}`;
  const signature = await cryptoApi.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    keyPair.privateKey,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64url(new Uint8Array(signature))}`;
}

function installTestJwks() {
  globalThis.fetch = async (url) => {
    assert.equal(
      String(url),
      'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
    );
    return { ok: true, json: async () => ({ keys: [publicJwk] }) };
  };
}

function makeEnv({ rows = [], failRun = false, failAll = false, noDb = false, revokedAfter = null, failSessionCheck = false } = {}) {
  const calls = [];
  const env = {
    ADMIN_FIREBASE_PROJECT_ID: ADMIN_PROJECT,
    ADMIN_DB: noDb ? undefined : {
      prepare(sql) {
        return {
          bind(...values) {
            calls.push({ sql, values });
            return {
              run: async () => {
                if (failRun) throw new Error('simulated D1 write failure');
                return { success: true };
              },
              all: async () => {
                if (failAll) throw new Error('simulated D1 read failure');
                return { results: rows };
              },
              first: async () => {
                if (failSessionCheck) throw new Error('simulated session check failure');
                return revokedAfter === null ? null : { revoked_after: revokedAfter };
              },
            };
          },
        };
      },
    },
  };
  return { env, calls };
}

async function requestAuditLogs(token, env, limit = '50') {
  return worker.fetch(
    new Request(`https://contentnex-api.test/v1/admin/audit-logs?limit=${limit}`, {
      headers: { Authorization: `Bearer ${token}` },
    }),
    env,
  );
}

test('super_admin can read audit logs and the read action is recorded', async () => {
  installTestJwks();
  const token = await createIdToken();
  const rows = [{
    id: 'log-1',
    actor_uid: 'audit-test-admin-uid',
    action: 'admin.access_check',
    resource_type: 'admin',
    resource_id: null,
    outcome: 'success',
    details_json: '{"source":"test"}',
    created_at: 1794850000,
  }];
  const { env, calls } = makeEnv({ rows });

  const response = await requestAuditLogs(token, env, '25');
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.limit, 25);
  assert.equal(body.items.length, 1);
  assert.equal(body.items[0].actorUid, 'audit-test-admin-uid');
  assert.deepEqual(body.items[0].details, { source: 'test' });
  assert.equal(calls.length, 2);
  assert.match(calls[0].sql, /INSERT INTO admin_audit_logs/);
  assert.equal(calls[0].values[2], 'admin.audit_logs.read');
  assert.match(calls[1].sql, /SELECT id, actor_uid, action/);
  assert.equal(calls[1].values[0], 25);
});

test('customer role cannot read admin audit logs', async () => {
  installTestJwks();
  const token = await createIdToken({ contentnexRole: 'customer' });
  const { env, calls } = makeEnv();

  const response = await requestAuditLogs(token, env);
  assert.equal(response.status, 403);
  assert.equal((await response.json()).error.code, 'FORBIDDEN');
  assert.equal(calls.length, 1);
  assert.match(calls[0].sql, /INSERT INTO admin_audit_logs/);
  assert.equal(calls[0].values[2], 'admin.audit_logs.read');
  assert.equal(calls[0].values[5], 'denied');
  assert.deepEqual(JSON.parse(calls[0].values[6]), {
    reason: 'insufficient_role',
    role: 'customer',
  });
});

test('denied admin access is not silently accepted when audit write fails', async () => {
  installTestJwks();
  const token = await createIdToken({ contentnexRole: 'customer' });
  const { env } = makeEnv({ failRun: true });

  const response = await requestAuditLogs(token, env);
  assert.equal(response.status, 503);
  assert.equal((await response.json()).error.code, 'AUDIT_LOG_WRITE_FAILED');
});

test('audit log endpoint requires a valid admin token', async () => {
  installTestJwks();
  const { env, calls } = makeEnv();

  const response = await worker.fetch(
    new Request('https://contentnex-api.test/v1/admin/audit-logs'),
    env,
  );

  assert.equal(response.status, 401);
  assert.equal((await response.json()).error.code, 'UNAUTHENTICATED');
  assert.equal(calls.length, 0);
});

test('audit log limit is capped at 100', async () => {
  installTestJwks();
  const token = await createIdToken();
  const { env, calls } = makeEnv();

  const response = await requestAuditLogs(token, env, '999');
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.limit, 100);
  assert.equal(calls[1].values[0], 100);
});

test('audit log endpoint fails closed when the admin database is missing', async () => {
  installTestJwks();
  const token = await createIdToken();
  const { env } = makeEnv({ noDb: true });

  const response = await requestAuditLogs(token, env);
  assert.equal(response.status, 503);
  assert.equal((await response.json()).error.code, 'ADMIN_SESSION_CHECK_UNAVAILABLE');
});

test('audit log endpoint returns service unavailable when D1 read fails', async () => {
  installTestJwks();
  const token = await createIdToken();
  const { env } = makeEnv({ failAll: true });

  const response = await requestAuditLogs(token, env);
  assert.equal(response.status, 503);
  assert.equal((await response.json()).error.code, 'AUDIT_LOG_READ_FAILED');
});

test('revoked admin token cannot read audit logs', async () => {
  installTestJwks();
  const now = Math.floor(Date.now() / 1000);
  const token = await createIdToken({ auth_time: now - 60 });
  const { env, calls } = makeEnv({ revokedAfter: now - 30 });

  const response = await requestAuditLogs(token, env);

  assert.equal(response.status, 401);
  assert.equal((await response.json()).error.code, 'TOKEN_REVOKED');
  assert.equal(calls.length, 1);
  assert.match(calls[0].sql, /INSERT INTO admin_audit_logs/);
  assert.equal(calls[0].values[2], 'admin.session_check');
  assert.equal(calls[0].values[5], 'denied');
});

test('admin audit endpoint fails closed when session revocation lookup fails', async () => {
  installTestJwks();
  const token = await createIdToken();
  const { env } = makeEnv({ failSessionCheck: true });

  const response = await requestAuditLogs(token, env);

  assert.equal(response.status, 503);
  assert.equal((await response.json()).error.code, 'ADMIN_SESSION_CHECK_UNAVAILABLE');
});
