const FIREBASE_JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

const ALLOWED_TASKS = new Set([
  'council_strategy',
  'copywriter',
  'poster_brief',
  'video_script',
  'content_plan',
  'quality_review',
]);
const CONTENTNEX_ROLES = new Set(['customer', 'support', 'super_admin']);
const ALLOWED_REQUEST_FIELDS = new Set([
  'task', 'prompt', 'languageCode', 'context', 'consent',
]);

const json = (body, status = 200, headers = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', ...headers },
  });

async function writeAdminAudit(env, claims, action, outcome = 'success', details = {}) {
  if (!env.ADMIN_DB) return false;
  const safeDetails = JSON.stringify(details);
  await env.ADMIN_DB.prepare(
    `INSERT INTO admin_audit_logs
      (id, actor_uid, action, resource_type, resource_id, outcome, details_json, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
  ).bind(
    crypto.randomUUID(),
    claims.sub,
    action,
    'admin',
    null,
    outcome,
    safeDetails,
    Math.floor(Date.now() / 1000),
  ).run();
  return true;
}

function corsHeaders(request, env) {
  const origin = request.headers.get('Origin');
  if (!origin || !env.APP_ORIGIN || origin !== env.APP_ORIGIN) return {};
  return {
    'access-control-allow-origin': origin,
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'Authorization, Content-Type',
    'access-control-max-age': '600',
    vary: 'Origin',
  };
}

function decodeBase64Url(value) {
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=');
  const binary = atob(padded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function decodeJsonSegment(segment) {
  return JSON.parse(new TextDecoder().decode(decodeBase64Url(segment)));
}

async function loadSigningKey(kid) {
  const response = await fetch(FIREBASE_JWKS_URL, {
    headers: { accept: 'application/json' },
  });
  if (!response.ok) throw new Error('SIGNING_KEYS_UNAVAILABLE');
  const keySet = await response.json();
  const jwk = keySet.keys?.find((key) => key.kid === kid && key.kty === 'RSA');
  if (!jwk) throw new Error('SIGNING_KEY_NOT_FOUND');
  return crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
}

/** Only CONTENTNEX-specific claims grant roles in this application. */
export function getTrustedRole(claims) {
  if (!claims || typeof claims !== 'object' || Array.isArray(claims)) return 'customer';
  return CONTENTNEX_ROLES.has(claims.contentnexRole)
    ? claims.contentnexRole
    : 'customer';
}

/** Verify Firebase Authentication ID token and return trusted claims. */
export async function verifyFirebaseIdToken(token, projectId) {
  if (!projectId || typeof token !== 'string' || token.length > 8192) {
    throw new Error('INVALID_TOKEN');
  }

  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('INVALID_TOKEN');

  const header = decodeJsonSegment(parts[0]);
  const claims = decodeJsonSegment(parts[1]);
  if (header.alg !== 'RS256' || typeof header.kid !== 'string') {
    throw new Error('INVALID_TOKEN');
  }

  const now = Math.floor(Date.now() / 1000);
  const issuer = `https://securetoken.google.com/${projectId}`;
  if (
    claims.iss !== issuer ||
    claims.aud !== projectId ||
    typeof claims.sub !== 'string' ||
    claims.sub.length === 0 ||
    claims.sub.length > 128 ||
    !Number.isFinite(claims.exp) ||
    claims.exp <= now ||
    !Number.isFinite(claims.iat) ||
    claims.iat > now + 60 ||
    claims.iat < now - 3600 ||
    !Number.isFinite(claims.auth_time) ||
    claims.auth_time <= 0 ||
    claims.auth_time > now + 60 ||
    claims.email_verified !== true
  ) {
    throw new Error('INVALID_TOKEN_CLAIMS');
  }

  const key = await loadSigningKey(header.kid);
  const signedContent = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const signature = decodeBase64Url(parts[2]);
  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    key,
    signature,
    signedContent,
  );
  if (!valid) throw new Error('INVALID_TOKEN_SIGNATURE');
  return claims;
}

async function authenticate(request, env, projectId = env.FIREBASE_PROJECT_ID) {
  const authorization = request.headers.get('Authorization') ?? '';
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match || !projectId) return null;
  try {
    return await verifyFirebaseIdToken(match[1], projectId);
  } catch {
    return null;
  }
}

export function validateAiRequest(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return 'INVALID_BODY';

  if (Object.keys(body).some((key) => !ALLOWED_REQUEST_FIELDS.has(key))) {
    return 'UNKNOWN_REQUEST_FIELD';
  }
  if (typeof body.task !== 'string' || !ALLOWED_TASKS.has(body.task)) {
    return 'INVALID_TASK';
  }
  if (
    typeof body.prompt !== 'string' ||
    body.prompt.trim().length === 0 ||
    body.prompt.length > 12000
  ) {
    return 'INVALID_PROMPT';
  }
  if (
    body.languageCode !== undefined &&
    (typeof body.languageCode !== 'string' || body.languageCode.length > 35)
  ) {
    return 'INVALID_LANGUAGE';
  }
  if (body.context !== undefined) {
    if (
      !body.context ||
      typeof body.context !== 'object' ||
      Array.isArray(body.context) ||
      Object.keys(body.context).length > 10
    ) return 'INVALID_CONTEXT';
    for (const [key, value] of Object.entries(body.context)) {
      if (
        key.length > 64 ||
        typeof value !== 'string' ||
        value.length > 500
      ) return 'INVALID_CONTEXT';
    }
  }
  if (
    !body.consent ||
    typeof body.consent !== 'object' ||
    Array.isArray(body.consent) ||
    Object.keys(body.consent).some((key) => key !== 'externalAiProcessing') ||
    body.consent.externalAiProcessing !== true
  ) {
    return 'EXTERNAL_AI_CONSENT_REQUIRED';
  }
  return null;
}

export default {
  async fetch(request, env) {
    const headers = corsHeaders(request, env);
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      if (!headers['access-control-allow-origin']) {
        return json({ error: { code: 'ORIGIN_NOT_ALLOWED' } }, 403);
      }
      return new Response(null, { status: 204, headers });
    }

    if (url.pathname === '/v1/health' && request.method === 'GET') {
      return json({
        status: 'ok',
        service: 'contentnex-api',
        version: '0.3.0',
        aiProviderEnabled: false,
        adminAuditConfigured: Boolean(env.ADMIN_DB),
        adminAuthConfigured: Boolean(env.ADMIN_FIREBASE_PROJECT_ID),
      }, 200, headers);
    }

    if (url.pathname === '/v1/admin/access-check' && request.method === 'GET') {
      if (!env.ADMIN_FIREBASE_PROJECT_ID) {
        return json({ error: { code: 'ADMIN_AUTH_NOT_CONFIGURED' } }, 503, headers);
      }
      const claims = await authenticate(request, env, env.ADMIN_FIREBASE_PROJECT_ID);
      if (!claims) {
        return json({ error: { code: 'UNAUTHENTICATED' } }, 401, headers);
      }
      const role = getTrustedRole(claims);
      if (role !== 'super_admin') {
        return json({ error: { code: 'FORBIDDEN' } }, 403, headers);
      }
      let auditLogged = false;
      if (env.ADMIN_DB) {
        try {
          auditLogged = await writeAdminAudit(env, claims, 'admin.access_check', 'success');
        } catch {
          return json({ error: { code: 'AUDIT_LOG_WRITE_FAILED' } }, 503, headers);
        }
      }
      return json({
        authorized: true,
        role: 'super_admin',
        auditLogged,
        auditLogConfigured: Boolean(env.ADMIN_DB),
      }, 200, headers);
    }

    if (url.pathname === '/v1/admin/audit-logs' && request.method === 'GET') {
      if (!env.ADMIN_FIREBASE_PROJECT_ID) {
        return json({ error: { code: 'ADMIN_AUTH_NOT_CONFIGURED' } }, 503, headers);
      }
      const claims = await authenticate(request, env, env.ADMIN_FIREBASE_PROJECT_ID);
      if (!claims) {
        return json({ error: { code: 'UNAUTHENTICATED' } }, 401, headers);
      }
      if (getTrustedRole(claims) !== 'super_admin') {
        return json({ error: { code: 'FORBIDDEN' } }, 403, headers);
      }
      if (!env.ADMIN_DB) {
        return json({
          error: {
            code: 'ADMIN_DATABASE_NOT_CONFIGURED',
            message: 'Admin audit database is not connected.',
          },
        }, 503, headers);
      }

      const requestedLimit = Number(url.searchParams.get('limit') ?? 50);
      const limit = Number.isInteger(requestedLimit)
        ? Math.min(Math.max(requestedLimit, 1), 100)
        : 50;
      try {
        await writeAdminAudit(env, claims, 'admin.audit_logs.read', 'success', { limit });
        const result = await env.ADMIN_DB.prepare(
          `SELECT id, actor_uid, action, resource_type, resource_id, outcome, details_json, created_at
           FROM admin_audit_logs
           ORDER BY created_at DESC
           LIMIT ?`,
        ).bind(limit).all();
        return json({
          items: (result.results ?? []).map((row) => ({
            id: row.id,
            actorUid: row.actor_uid,
            action: row.action,
            resourceType: row.resource_type,
            resourceId: row.resource_id,
            outcome: row.outcome,
            details: row.details_json ? JSON.parse(row.details_json) : {},
            createdAt: row.created_at,
          })),
          limit,
        }, 200, headers);
      } catch {
        return json({ error: { code: 'AUDIT_LOG_READ_FAILED' } }, 503, headers);
      }
    }

    if (url.pathname === '/v1/ai/generate' && request.method === 'POST') {
      if (!env.FIREBASE_PROJECT_ID) {
        return json({ error: { code: 'SERVER_NOT_CONFIGURED' } }, 503, headers);
      }

      const claims = await authenticate(request, env);
      if (!claims) {
        return json({ error: { code: 'UNAUTHENTICATED' } }, 401, headers);
      }

      const declaredLength = Number(request.headers.get('Content-Length') ?? 0);
      if (declaredLength > 20000) {
        return json({ error: { code: 'REQUEST_TOO_LARGE' } }, 413, headers);
      }

      let body;
      try {
        const raw = await request.text();
        if (raw.length > 20000) {
          return json({ error: { code: 'REQUEST_TOO_LARGE' } }, 413, headers);
        }
        body = JSON.parse(raw);
      } catch {
        return json({ error: { code: 'INVALID_JSON' } }, 400, headers);
      }

      const validationError = validateAiRequest(body);
      if (validationError) {
        return json({ error: { code: validationError } }, 400, headers);
      }

      // Intentionally disabled: no Gemini calls, secrets, billing, or data forwarding.
      return json({
        error: {
          code: 'AI_PROVIDER_DISABLED',
          message: 'Automatic AI generation is not enabled yet.',
          retryable: false,
        },
      }, 503, headers);
    }

    return json({ error: { code: 'NOT_FOUND' } }, 404, headers);
  },
};
