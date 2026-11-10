const APP_NAME = "ADNEXA API";
const VERSION = "1.2.0";
const FIREBASE_PROJECT_ID = "adnexa-8daea";
const STATE_TTL = 600;

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff"
    }
  });

function decodeBase64Url(value) {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  const binary = atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, "="));
  return Uint8Array.from(binary, c => c.charCodeAt(0));
}

function decodeBase64(value) {
  const binary = atob(value);
  return Uint8Array.from(binary, c => c.charCodeAt(0));
}

function encodeBase64(bytes) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

async function sha256(value) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value)
  );
  return Array.from(new Uint8Array(digest))
    .map(b => b.toString(16).padStart(2, "0"))
    .join("");
}

async function verifyFirebaseToken(token) {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid token");

  const header = JSON.parse(
    new TextDecoder().decode(decodeBase64Url(parts[0]))
  );
  const payload = JSON.parse(
    new TextDecoder().decode(decodeBase64Url(parts[1]))
  );

  if (header.alg !== "RS256" || !header.kid) {
    throw new Error("Invalid token header");
  }

  const response = await fetch(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"
  );
  if (!response.ok) throw new Error("Unable to retrieve signing keys");

  const keys = await response.json();
  const jwk = keys.keys.find(key => key.kid === header.kid);
  if (!jwk) throw new Error("Unknown signing key");

  const publicKey = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"]
  );

  const valid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    publicKey,
    decodeBase64Url(parts[2]),
    new TextEncoder().encode(parts[0] + "." + parts[1])
  );

  const now = Math.floor(Date.now() / 1000);
  if (
    !valid ||
    payload.aud !== FIREBASE_PROJECT_ID ||
    payload.iss !== \`https://securetoken.google.com/\${FIREBASE_PROJECT_ID}\` ||
    typeof payload.sub !== "string" ||
    payload.sub.length === 0 ||
    payload.sub.length > 128 ||
    typeof payload.exp !== "number" ||
    payload.exp <= now ||
    typeof payload.iat !== "number" ||
    payload.iat > now + 60 ||
    typeof payload.auth_time !== "number" ||
    payload.auth_time > now + 60
  ) {
    throw new Error("Firebase authentication failed");
  }
  return payload.sub;
}

async function authenticate(request) {
  const authorization = request.headers.get("Authorization") || "";
  const match = authorization.match(/^Bearer (.+)$/);
  if (!match) throw new Error("Missing authentication");
  return verifyFirebaseToken(match[1]);
}

async function createState(env, provider, userId) {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  const state = Array.from(bytes)
    .map(b => b.toString(16).padStart(2, "0"))
    .join("");
  const now = Math.floor(Date.now() / 1000);

  await env.DB.prepare(
    "DELETE FROM oauth_states WHERE expires_at <= ?"
  ).bind(now).run();

  await env.DB.prepare(
    \`INSERT INTO oauth_states
     (state_hash, provider, user_id, expires_at, created_at)
     VALUES (?, ?, ?, ?, ?)\`
  ).bind(
    await sha256(state),
    provider,
    userId,
    now + STATE_TTL,
    now
  ).run();

  return state;
}

async function consumeState(env, provider, state) {
  if (!/^[a-f0-9]{64}$/.test(state || "")) return null;
  const now = Math.floor(Date.now() / 1000);
  return env.DB.prepare(
    \`DELETE FROM oauth_states
     WHERE state_hash = ?
       AND provider = ?
       AND expires_at > ?
     RETURNING user_id\`
  ).bind(await sha256(state), provider, now).first();
}

function requiredEnv(env, names) {
  const missing = names.filter(name =>
    typeof env[name] !== "string" || env[name].trim() === ""
  );
  return missing;
}

function metaVersion(env) {
  const version = env.META_GRAPH_API_VERSION || "v25.0";
  if (!/^v\d+\.\d+$/.test(version)) {
    throw new Error("Invalid Meta Graph API version configuration");
  }
  return version;
}

function buildMetaAuthorizationUrl(env, state) {
  const url = new URL(
    \`https://www.facebook.com/\${metaVersion(env)}/dialog/oauth\`
  );
  url.searchParams.set("client_id", env.META_APP_ID);
  url.searchParams.set("redirect_uri", env.META_REDIRECT_URI);
  url.searchParams.set("state", state);
  url.searchParams.set("response_type", "code");
  // Facebook Login for Business configuration controls the requested
  // business assets and permissions. Do not duplicate scopes here.
  url.searchParams.set("config_id", env.META_LOGIN_CONFIG_ID);
  return url.toString();
}

async function getMetaAccessToken(env, code) {
  const version = metaVersion(env);
  const endpoint = new URL(
    \`https://graph.facebook.com/\${version}/oauth/access_token\`
  );
  endpoint.searchParams.set("client_id", env.META_APP_ID);
  endpoint.searchParams.set("client_secret", env.META_APP_SECRET);
  endpoint.searchParams.set("redirect_uri", env.META_REDIRECT_URI);
  endpoint.searchParams.set("code", code);

  const response = await fetch(endpoint.toString(), {
    method: "GET",
    headers: { "Accept": "application/json" }
  });
  const result = await response.json().catch(() => ({}));

  if (!response.ok || typeof result.access_token !== "string") {
    // Never return or log the upstream response; it may contain sensitive data.
    throw new Error("Meta token exchange failed");
  }

  return {
    accessToken: result.access_token,
    expiresIn: Number.isFinite(Number(result.expires_in))
      ? Number(result.expires_in)
      : null,
    tokenType: typeof result.token_type === "string"
      ? result.token_type
      : "bearer"
  };
}

async function getMetaIdentity(env, accessToken) {
  const endpoint = new URL(
    \`https://graph.facebook.com/\${metaVersion(env)}/me\`
  );
  endpoint.searchParams.set("fields", "id,name");
  endpoint.searchParams.set("access_token", accessToken);

  const response = await fetch(endpoint.toString(), {
    headers: { "Accept": "application/json" }
  });
  const result = await response.json().catch(() => ({}));

  if (!response.ok || typeof result.id !== "string") {
    throw new Error("Unable to verify Meta account identity");
  }

  return {
    id: result.id,
    name: typeof result.name === "string" ? result.name : null
  };
}

async function encryptionKey(env) {
  const raw = decodeBase64(env.META_TOKEN_ENCRYPTION_KEY);
  if (raw.length !== 32) {
    throw new Error("META_TOKEN_ENCRYPTION_KEY must decode to 32 bytes");
  }
  return crypto.subtle.importKey(
    "raw",
    raw,
    { name: "AES-GCM" },
    false,
    ["encrypt", "decrypt"]
  );
}

async function encryptToken(env, token) {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const key = await encryptionKey(env);
  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    key,
    new TextEncoder().encode(token)
  );
  return {
    ciphertext: encodeBase64(new Uint8Array(encrypted)),
    iv: encodeBase64(iv)
  };
}

async function decryptToken(env, row) {
  const key = await encryptionKey(env);
  const plaintext = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: decodeBase64(row.token_iv) },
    key,
    decodeBase64(row.token_ciphertext)
  );
  return new TextDecoder().decode(plaintext);
}

async function ensureMetaTable(env) {
  await env.DB.prepare(
    \`CREATE TABLE IF NOT EXISTS meta_connections (
      user_id TEXT PRIMARY KEY,
      meta_user_id TEXT NOT NULL,
      meta_name TEXT,
      token_ciphertext TEXT NOT NULL,
      token_iv TEXT NOT NULL,
      token_type TEXT NOT NULL DEFAULT 'bearer',
      expires_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )\`
  ).run();
}

function callbackPage(title, message, success = false) {
  const safeTitle = success ? "เชื่อมต่อ Meta สำเร็จ" : "เชื่อมต่อ Meta ไม่สำเร็จ";
  const safeMessage = success
    ? "บัญชีได้รับการเชื่อมต่อแล้ว คุณสามารถกลับไปยังแอป ADNEXA ได้"
    : "ไม่สามารถเชื่อมต่อบัญชีได้ กรุณากลับไปที่ ADNEXA แล้วลองใหม่อีกครั้ง";
  return new Response(
    \`<!doctype html><html lang="th"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>\${safeTitle}</title><body><main><h1>\${safeTitle}</h1><p>\${safeMessage}</p></main></body></html>\`,
    {
      status: success ? 200 : 400,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "no-store",
        "Referrer-Policy": "no-referrer",
        "X-Content-Type-Options": "nosniff",
        "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'"
      }
    }
  );
}

async function handleMetaStart(request, env) {
  let userId;
  try {
    userId = await authenticate(request);
  } catch {
    return json({ error: "Unauthorized" }, 401);
  }

  const missing = requiredEnv(env, [
    "META_APP_ID",
    "META_LOGIN_CONFIG_ID",
    "META_REDIRECT_URI"
  ]);
  if (missing.length) {
    return json({
      error: "Meta OAuth is not configured",
      missing_configuration: missing
    }, 503);
  }

  const state = await createState(env, "meta", userId);
  return json({
    status: "authorization_required",
    provider: "meta",
    authorization_url: buildMetaAuthorizationUrl(env, state),
    expires_in: STATE_TTL
  });
}

async function handleMetaCallback(url, env) {
  const state = url.searchParams.get("state");
  const code = url.searchParams.get("code");
  const error = url.searchParams.get("error");

  if (!state) return callbackPage("", "", false);

  const record = await consumeState(env, "meta", state);
  if (!record) return callbackPage("", "", false);
  if (error || !code) return callbackPage("", "", false);

  const missing = requiredEnv(env, [
    "META_APP_ID",
    "META_APP_SECRET",
    "META_REDIRECT_URI",
    "META_TOKEN_ENCRYPTION_KEY"
  ]);
  if (missing.length) return callbackPage("", "", false);

  const token = await getMetaAccessToken(env, code);
  const identity = await getMetaIdentity(env, token.accessToken);
  const encrypted = await encryptToken(env, token.accessToken);
  await ensureMetaTable(env);

  const now = Math.floor(Date.now() / 1000);
  const expiresAt = token.expiresIn === null
    ? null
    : now + Math.max(0, token.expiresIn);

  await env.DB.prepare(
    \`INSERT INTO meta_connections
      (user_id, meta_user_id, meta_name, token_ciphertext, token_iv,
       token_type, expires_at, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(user_id) DO UPDATE SET
       meta_user_id = excluded.meta_user_id,
       meta_name = excluded.meta_name,
       token_ciphertext = excluded.token_ciphertext,
       token_iv = excluded.token_iv,
       token_type = excluded.token_type,
       expires_at = excluded.expires_at,
       updated_at = excluded.updated_at\`
  ).bind(
    record.user_id,
    identity.id,
    identity.name,
    encrypted.ciphertext,
    encrypted.iv,
    token.tokenType,
    expiresAt,
    now,
    now
  ).run();

  return callbackPage("", "", true);
}

async function getAuthenticatedMetaConnection(request, env) {
  let userId;
  try {
    userId = await authenticate(request);
  } catch {
    return { response: json({ error: "Unauthorized" }, 401) };
  }

  await ensureMetaTable(env);
  const row = await env.DB.prepare(
    "SELECT * FROM meta_connections WHERE user_id = ? LIMIT 1"
  ).bind(userId).first();

  if (!row) {
    return { response: json({ connected: false, provider: "meta" }) };
  }

  if (row.expires_at !== null && row.expires_at <= Math.floor(Date.now() / 1000)) {
    return {
      response: json({
        connected: false,
        provider: "meta",
        reason: "token_expired"
      })
    };
  }

  return { userId, row };
}

async function handleMetaConnection(request, env) {
  const result = await getAuthenticatedMetaConnection(request, env);
  if (result.response) return result.response;
  return json({
    connected: true,
    provider: "meta",
    account: {
      id: result.row.meta_user_id,
      name: result.row.meta_name
    },
    expires_at: result.row.expires_at
  });
}

async function handleMetaAdAccounts(request, env) {
  const result = await getAuthenticatedMetaConnection(request, env);
  if (result.response) return result.response;

  let accessToken;
  try {
    accessToken = await decryptToken(env, result.row);
  } catch {
    return json({ error: "Stored Meta credential unavailable" }, 503);
  }

  const endpoint = new URL(
    \`https://graph.facebook.com/\${metaVersion(env)}/me/adaccounts\`
  );
  endpoint.searchParams.set(
    "fields",
    "id,name,account_status,currency,timezone_name"
  );
  endpoint.searchParams.set("limit", "100");
  endpoint.searchParams.set("access_token", accessToken);

  const response = await fetch(endpoint.toString(), {
    headers: { "Accept": "application/json" }
  });
  const resultBody = await response.json().catch(() => ({}));

  if (!response.ok || !Array.isArray(resultBody.data)) {
    return json({
      error: "Unable to retrieve Meta ad accounts",
      reauthorization_required: response.status === 401
    }, response.status === 401 ? 401 : 502);
  }

  return json({
    provider: "meta",
    accounts: resultBody.data.map(account => ({
      id: account.id,
      name: account.name || null,
      status: account.account_status ?? null,
      currency: account.currency || null,
      timezone: account.timezone_name || null
    })),
    has_more: !!(resultBody.paging && resultBody.paging.next)
  });
}

async function handleMetaDisconnect(request, env) {
  let userId;
  try {
    userId = await authenticate(request);
  } catch {
    return json({ error: "Unauthorized" }, 401);
  }

  await ensureMetaTable(env);
  await env.DB.prepare(
    "DELETE FROM meta_connections WHERE user_id = ?"
  ).bind(userId).run();

  return json({ status: "disconnected", provider: "meta" });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    try {
      if (method === "GET" && path === "/") {
        return json({ app: APP_NAME, version: VERSION, status: "online" });
      }

      if (method === "GET" && path === "/health") {
        return json({
          status: "healthy",
          service: APP_NAME,
          version: VERSION,
          timestamp: new Date().toISOString()
        });
      }

      if (method === "GET" && path === "/health/db") {
        try {
          await env.DB.prepare("SELECT 1 AS ok").first();
          const table = await env.DB.prepare(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1"
          ).bind("oauth_states").first();
          return json({
            status: table ? "healthy" : "unhealthy",
            database: "connected",
            table_exists: !!table,
            table: "oauth_states"
          }, table ? 200 : 503);
        } catch {
          return json({
            status: "unhealthy",
            database: "error",
            table_exists: false
          }, 503);
        }
      }

      const metaStartMatch = path === "/api/oauth/meta/start";
      if (method === "POST" && metaStartMatch) {
        return await handleMetaStart(request, env);
      }

      if (method === "GET" && path === "/api/meta/callback") {
        return await handleMetaCallback(url, env);
      }

      if (method === "GET" && path === "/api/meta/connection") {
        return await handleMetaConnection(request, env);
      }

      if (method === "GET" && path === "/api/meta/ad-accounts") {
        return await handleMetaAdAccounts(request, env);
      }

      if (method === "DELETE" && path === "/api/meta/connection") {
        return await handleMetaDisconnect(request, env);
      }

      // Keep the existing TikTok state/callback behavior unchanged until
      // its provider-specific OAuth configuration is implemented.
      const startMatch = path.match(/^\/api\/oauth\/(tiktok)\/start$/);
      if (method === "POST" && startMatch) {
        let userId;
        try {
          userId = await authenticate(request);
        } catch {
          return json({ error: "Unauthorized" }, 401);
        }
        const state = await createState(env, "tiktok", userId);
        return json({
          status: "state_created",
          provider: "tiktok",
          state,
          expires_in: STATE_TTL
        });
      }

      if (method === "GET" && path === "/api/tiktok/callback") {
        const state = url.searchParams.get("state");
        const code = url.searchParams.get("code");
        const error = url.searchParams.get("error");
        if (!state) return json({ error: "Missing OAuth state" }, 400);
        const record = await consumeState(env, "tiktok", state);
        if (!record) {
          return json({ error: "Invalid, expired, or already used state" }, 400);
        }
        if (error) return json({ provider: "tiktok", status: "authorization_denied" }, 400);
        if (!code) return json({ error: "Missing authorization code" }, 400);
        return json({
          provider: "tiktok",
          status: "state_verified",
          next_step: "Server-side OAuth code exchange not configured"
        }, 501);
      }

      if (path.startsWith("/api/")) {
        return json({ error: "API endpoint not found" }, 404);
      }
      return json({ error: "Not found" }, 404);
    } catch {
      return json({ error: "Internal server error" }, 500);
    }
  }
};
