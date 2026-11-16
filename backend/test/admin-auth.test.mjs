import test, { afterEach } from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.mjs';

const ADMIN_PROJECT = 'contentnex-admin';
const originalFetch = globalThis.fetch;
const cryptoApi = globalThis.crypto;

if (!cryptoApi?.subtle) {
  throw new Error('WebCrypto is required for Admin Authentication tests');
}

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
publicJwk.kid = 'contentnex-test-key';

afterEach(() => {
  globalThis.fetch = originalFetch;
});

function base64url(value) {
  return Buffer.from(value).toString('base64url');
}

async function createIdToken(overrides = {}, signingKey = keyPair.privateKey) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT', kid: publicJwk.kid };
  const claims = {
    iss: `https://securetoken.google.com/${ADMIN_PROJECT}`,
    aud: ADMIN_PROJECT,
    sub: 'test-super-admin-uid',
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
    signingKey,
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
    return {
      ok: true,
      json: async () => ({ keys: [publicJwk] }),
    };
  };
}

function makeEnv(overrides = {}) {
  const auditWrites = [];
  const env = {
    ADMIN_FIREBASE_PROJECT_ID: ADMIN_PROJECT,
    ADMIN_DB: {
      prepare(sql) {
        return {
          bind(...values) {
            return {
              run: async () => {
                auditWrites.push({ sql, values });
                return { success: true };
              },
            };
          },
        };
      },
    },
    ...overrides,
  };
  return { env, auditWrites };
}

test('valid signed super_admin token is authorized and writes an audit event', async () => {
  installTestJwks();
  const token = await createIdToken();
  const { env, auditWrites } = makeEnv();

  const response = await worker.fetch(
    new Request('https://contentnex-api.test/v1/admin/access-check', {
      headers: { Authorization: `Bearer ${token}` },
    }),
    env,
  );
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.authorized, true);
  assert.equal(body.role, 'super_admin');
  assert.equal(body.auditLogged, true);
  assert.equal(auditWrites.length, 1);
  assert.equal(auditWrites[0].values[1], 'test-super-admin-uid');
  assert.equal(auditWrites[0].values[2], 'admin.access_check');
});

test('valid Firebase token without super_admin claim is forbidden', async () => {
  installTestJwks();
  const token = await createIdToken({ contentnexRole: 'customer' });
  const { env, auditWrites } = makeEnv();

  const response = await worker.fetch(
    new Request('https://contentnex-api.test/v1/admin/access-check', {
      headers: { Authorization: `Bearer ${token}` },
    }),
    env,
  );
  const body = await response.json();

  assert.equal(response.status, 403);
  assert.equal(body.error.code, 'FORBIDDEN');
  assert.equal(auditWrites.length, 1);
  assert.match(auditWrites[0].sql, /INSERT INTO admin_audit_logs/);
  assert.equal(auditWrites[0].values[1], 'test-super-admin-uid');
  assert.equal(auditWrites[0].values[2], 'admin.access_check');
  assert.equal(auditWrites[0].values[5], 'denied');
  assert.deepEqual(JSON.parse(auditWrites[0].values[6]), {
    reason: 'insufficient_role',
    role: 'customer',
  });
});

test('token signed by an untrusted key is rejected', async () => {
  installTestJwks();
  const otherKeyPair = await cryptoApi.subtle.generateKey(
    {
      name: 'RSASSA-PKCS1-v1_5',
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: 'SHA-256',
    },
    true,
    ['sign', 'verify'],
  );
  const token = await createIdToken({}, otherKeyPair.privateKey);
  const { env } = makeEnv();

  const response = await worker.fetch(
    new Request('https://contentnex-api.test/v1/admin/access-check', {
      headers: { Authorization: `Bearer ${token}` },
    }),
    env,
  );

  assert.equal(response.status, 401);
  assert.equal((await response.json()).error.code, 'UNAUTHENTICATED');
});

test('token for a different Firebase project is rejected', async () => {
  installTestJwks();
  const token = await createIdToken({ aud: 'adnexa-8daea' });
  const { env } = makeEnv();

  const response = await worker.fetch(
    new Request('https://contentnex-api.test/v1/admin/access-check', {
      headers: { Authorization: `Bearer ${token}` },
    }),
    env,
  );

  assert.equal(response.status, 401);
  assert.equal((await response.json()).error.code, 'UNAUTHENTICATED');
});

test('expired token is rejected', async () => {
  installTestJwks();
  const now = Math.floor(Date.now() / 1000);
  const token = await createIdToken({ exp: now - 1 });
  const { env } = makeEnv();

  const response = await worker.fetch(
    new Request('https://contentnex-api.test/v1/admin/access-check', {
      headers: { Authorization: `Bearer ${token}` },
    }),
    env,
  );

  assert.equal(response.status, 401);
  assert.equal((await response.json()).error.code, 'UNAUTHENTICATED');
});

test('admin endpoint fails closed when the dedicated admin project is not configured', async () => {
  const { env } = makeEnv({ ADMIN_FIREBASE_PROJECT_ID: '' });

  const response = await worker.fetch(
    new Request('https://contentnex-api.test/v1/admin/access-check'),
    env,
  );

  assert.equal(response.status, 503);
  assert.equal((await response.json()).error.code, 'ADMIN_AUTH_NOT_CONFIGURED');
});
