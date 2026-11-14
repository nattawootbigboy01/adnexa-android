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
const ALLOWED_REQUEST_FIELDS = new Set([
  'task', 'prompt', 'languageCode', 'context', 'consent',
]);

const json = (body, status = 200, headers = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', ...headers },
  });

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

async function authenticate(request, env) {
  const authorization = request.headers.get('Authorization') ?? '';
  const match = authorization.match(/^Bearer\\s+(.+)$/i);
  if (!match) return null;
  try {
    return await verifyFirebaseIdToken(match[1], env.FIREBASE_PROJECT_ID);
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
        version: '0.1.0',
        aiProviderEnabled: false,
      }, 200, headers);
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
