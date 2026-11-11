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

async function verifyFirebaseToken(token, includeClaims = false) {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid token");

  const header = JSON.parse(new TextDecoder().decode(decodeBase64Url(parts[0])));
  const payload = JSON.parse(new TextDecoder().decode(decodeBase64Url(parts[1])));

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
    payload.iss !== "https://securetoken.google.com/" + FIREBASE_PROJECT_ID ||
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
  return includeClaims ? payload : payload.sub;
}

async function authenticate(request) {
  const authorization = request.headers.get("Authorization") || "";
  const match = authorization.match(/^Bearer (.+)$/);
  if (!match) throw new Error("Missing authentication");
  return verifyFirebaseToken(match[1]);
}

async function ensureAdminTables(env) {
  await env.DB.prepare(
    "CREATE TABLE IF NOT EXISTS member_directory (uid TEXT PRIMARY KEY, email TEXT, display_name TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, last_seen_at INTEGER NOT NULL)"
  ).run();
  await env.DB.prepare(
    "CREATE TABLE IF NOT EXISTS admin_roles (uid TEXT PRIMARY KEY, role TEXT NOT NULL CHECK(role IN ('super_admin','admin','support')), granted_by TEXT NOT NULL, granted_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)"
  ).run();
  await env.DB.prepare(
    "CREATE TABLE IF NOT EXISTS admin_audit_details (id INTEGER PRIMARY KEY AUTOINCREMENT, admin_uid TEXT NOT NULL, action TEXT NOT NULL, target_uid TEXT, details TEXT, created_at INTEGER NOT NULL)"
  ).run();
}

async function getStoredAdminRole(env, uid) {
  const row = await env.DB.prepare(
    "SELECT role FROM admin_roles WHERE uid = ? LIMIT 1"
  ).bind(uid).first();
  return row && typeof row.role === "string" ? row.role : null;
}

async function authenticateAdmin(request, env, allowedRoles = ["super_admin", "admin", "support"]) {
  const authorization = request.headers.get("Authorization") || "";
  const match = authorization.match(/^Bearer (.+)$/);
  if (!match) throw new Error("Missing authentication");
  const claims = await verifyFirebaseToken(match[1], true);
  await ensureAdminTables(env);
  const uid = claims.sub;
  const now = Math.floor(Date.now() / 1000);

  // Bootstrap only the already-trusted Firebase admin claim. Existing D1 roles
  // remain authoritative after the first bootstrap.
  if (claims.admin === true) {
    await env.DB.prepare(
      "INSERT OR IGNORE INTO admin_roles (uid, role, granted_by, granted_at, updated_at) VALUES (?, 'super_admin', ?, ?, ?)"
    ).bind(uid, uid, now, now).run();
  } else if (claims.role === "admin") {
    await env.DB.prepare(
      "INSERT OR IGNORE INTO admin_roles (uid, role, granted_by, granted_at, updated_at) VALUES (?, 'admin', ?, ?, ?)"
    ).bind(uid, uid, now, now).run();
  }

  const role = await getStoredAdminRole(env, uid);
  if (!role || !allowedRoles.includes(role)) {
    throw new Error("Administrator access required");
  }
  return uid;
}

async function ensureAdminAuditTable(env) {
  await env.DB.prepare(
    "CREATE TABLE IF NOT EXISTS admin_audit_log (id INTEGER PRIMARY KEY AUTOINCREMENT, admin_uid TEXT NOT NULL, action TEXT NOT NULL, created_at INTEGER NOT NULL)"
  ).run();
}

async function recordAdminAction(env, adminUid, action) {
  await ensureAdminAuditTable(env);
  await env.DB.prepare(
    "INSERT INTO admin_audit_log (admin_uid, action, created_at) VALUES (?, ?, ?)"
  ).bind(adminUid, action, Math.floor(Date.now() / 1000)).run();
}

async function handleAdminOverview(request, env) {
  let adminUid;
  try { adminUid = await authenticateAdmin(request, env); }
  catch (error) {
    const forbidden = error.message === "Administrator access required";
    return json({ error: forbidden ? "Forbidden" : "Unauthorized" }, forbidden ? 403 : 401);
  }

  await ensureMetaTable(env);
  const now = Math.floor(Date.now() / 1000);
  const totals = await env.DB.prepare(
    "SELECT COUNT(*) AS connected_users, SUM(CASE WHEN expires_at IS NULL OR expires_at > ? THEN 1 ELSE 0 END) AS active_connections FROM meta_connections"
  ).bind(now).first();
  await recordAdminAction(env, adminUid, "view_overview");
  const adminRole = await getStoredAdminRole(env, adminUid);
  return json({
    role: adminRole || "customer",
    metrics: {
      connected_users: Number(totals && totals.connected_users || 0),
      active_connections: Number(totals && totals.active_connections || 0)
    },
    capabilities: {
      user_directory: true,
      role_management: adminRole === "super_admin",
      campaign_controls: false,
      ad_spend_controls: false
    }
  });
}

async function handleAdminConnections(request, env) {
  let adminUid;
  try { adminUid = await authenticateAdmin(request); }
  catch (error) {
    const forbidden = error.message === "Administrator access required";
    return json({ error: forbidden ? "Forbidden" : "Unauthorized" }, forbidden ? 403 : 401);
  }

  await ensureMetaTable(env);
  const rows = await env.DB.prepare(
    "SELECT user_id, meta_user_id, meta_name, expires_at, updated_at FROM meta_connections ORDER BY updated_at DESC LIMIT 100"
  ).all();
  await recordAdminAction(env, adminUid, "view_meta_connections");
  return json({
    connections: (rows.results || []).map(row => ({
      user_id: row.user_id,
      meta_user_id: row.meta_user_id,
      meta_name: row.meta_name,
      expires_at: row.expires_at,
      updated_at: row.updated_at
    }))
  });
}

async function handleAdminAudit(request, env) {
  let adminUid;
  try { adminUid = await authenticateAdmin(request); }
  catch (error) {
    const forbidden = error.message === "Administrator access required";
    return json({ error: forbidden ? "Forbidden" : "Unauthorized" }, forbidden ? 403 : 401);
  }

  await ensureAdminAuditTable(env);
  const rows = await env.DB.prepare(
    "SELECT admin_uid, action, created_at FROM admin_audit_log ORDER BY created_at DESC LIMIT 50"
  ).all();
  await recordAdminAction(env, adminUid, "view_audit_log");
  return json({ events: rows.results || [] });
}

async function handleMemberSync(request, env) {
  let claims;
  try {
    const authorization = request.headers.get("Authorization") || "";
    const match = authorization.match(/^Bearer (.+)$/);
    if (!match) return json({ error: "Unauthorized" }, 401);
    claims = await verifyFirebaseToken(match[1], true);
  } catch {
    return json({ error: "Unauthorized" }, 401);
  }

  if (claims.email_verified !== true || typeof claims.email !== "string" || !claims.email.includes("@")) {
    return json({ error: "Verified email required" }, 403);
  }
  await ensureAdminTables(env);
  const now = Math.floor(Date.now() / 1000);
  const uid = claims.sub;
  const email = claims.email.trim().toLowerCase().slice(0, 254);
  const displayName = typeof claims.name === "string" ? claims.name.trim().slice(0, 120) : null;
  await env.DB.prepare(
    "INSERT INTO member_directory (uid, email, display_name, created_at, updated_at, last_seen_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(uid) DO UPDATE SET email = excluded.email, display_name = COALESCE(excluded.display_name, member_directory.display_name), updated_at = excluded.updated_at, last_seen_at = excluded.last_seen_at"
  ).bind(uid, email, displayName, now, now, now).run();
  return json({ status: "synced" });
}

async function handleAdminAccess(request, env) {
  let adminUid;
  try { adminUid = await authenticateAdmin(request, env); }
  catch (error) {
    const forbidden = error.message === "Administrator access required";
    return json({ error: forbidden ? "Forbidden" : "Unauthorized" }, forbidden ? 403 : 401);
  }
  const role = await getStoredAdminRole(env, adminUid);
  await recordAdminAction(env, adminUid, "check_admin_access");
  return json({
    uid: adminUid,
    role: role,
    capabilities: {
      view_members: ["super_admin", "admin", "support"].includes(role),
      manage_roles: role === "super_admin",
      campaign_controls: false,
      ad_spend_controls: false
    }
  });
}

async function handleAdminMembers(request, env) {
  let adminUid;
  try { adminUid = await authenticateAdmin(request, env); }
  catch (error) {
    const forbidden = error.message === "Administrator access required";
    return json({ error: forbidden ? "Forbidden" : "Unauthorized" }, forbidden ? 403 : 401);
  }
  await ensureAdminTables(env);
  const url = new URL(request.url);
  const rawSearch = (url.searchParams.get("search") || "").trim().slice(0, 100);
  const limit = Math.max(1, Math.min(100, Number.parseInt(url.searchParams.get("limit") || "50", 10) || 50));
  const role = await getStoredAdminRole(env, adminUid);
  const rows = rawSearch
    ? await env.DB.prepare(
        "SELECT m.uid, m.email, m.display_name, m.created_at, m.updated_at, m.last_seen_at, COALESCE(r.role, 'customer') AS role FROM member_directory m LEFT JOIN admin_roles r ON r.uid = m.uid WHERE m.email LIKE ? OR m.display_name LIKE ? OR m.uid LIKE ? ORDER BY m.last_seen_at DESC LIMIT ?"
      ).bind("%" + rawSearch + "%", "%" + rawSearch + "%", "%" + rawSearch + "%", limit).all()
    : await env.DB.prepare(
        "SELECT m.uid, m.email, m.display_name, m.created_at, m.updated_at, m.last_seen_at, COALESCE(r.role, 'customer') AS role FROM member_directory m LEFT JOIN admin_roles r ON r.uid = m.uid ORDER BY m.last_seen_at DESC LIMIT ?"
      ).bind(limit).all();
  await recordAdminAction(env, adminUid, "view_member_directory");
  return json({
    members: rows.results || [],
    current_role: role,
    can_manage_roles: role === "super_admin",
    limit
  });
}

async function handleAdminRoleUpdate(request, env, targetUid) {
  let adminUid;
  try { adminUid = await authenticateAdmin(request, env, ["super_admin"]); }
  catch (error) {
    const forbidden = error.message === "Administrator access required";
    return json({ error: forbidden ? "Forbidden" : "Unauthorized" }, forbidden ? 403 : 401);
  }

  if (!targetUid || targetUid.length > 128 || targetUid === adminUid) {
    return json({ error: "Invalid target account" }, 400);
  }
  let body;
  try { body = await request.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }
  const role = body && body.role;
  if (!["customer", "admin", "support"].includes(role)) {
    return json({ error: "Role must be customer, admin, or support" }, 400);
  }

  await ensureAdminTables(env);
  const member = await env.DB.prepare(
    "SELECT uid FROM member_directory WHERE uid = ? LIMIT 1"
  ).bind(targetUid).first();
  if (!member) return json({ error: "Member not found; the user must sign in to ADNEXA first" }, 404);

  const existing = await getStoredAdminRole(env, targetUid);
  if (existing === "super_admin") {
    return json({ error: "Super administrator role cannot be changed here" }, 403);
  }
  const now = Math.floor(Date.now() / 1000);
  if (role === "customer") {
    await env.DB.prepare("DELETE FROM admin_roles WHERE uid = ? AND role != 'super_admin'")
      .bind(targetUid).run();
  } else {
    await env.DB.prepare(
      "INSERT INTO admin_roles (uid, role, granted_by, granted_at, updated_at) VALUES (?, ?, ?, ?, ?) ON CONFLICT(uid) DO UPDATE SET role = excluded.role, granted_by = excluded.granted_by, updated_at = excluded.updated_at"
    ).bind(targetUid, role, adminUid, now, now).run();
  }
  await env.DB.prepare(
    "INSERT INTO admin_audit_details (admin_uid, action, target_uid, details, created_at) VALUES (?, ?, ?, ?, ?)"
  ).bind(adminUid, "change_member_role", targetUid, JSON.stringify({ role: role }), now).run();
  await recordAdminAction(env, adminUid, "change_member_role");
  return json({ status: "updated", uid: targetUid, role: role });
}

async function handleAdminRoles(request, env) {
  let adminUid;
  try { adminUid = await authenticateAdmin(request, env); }
  catch (error) {
    const forbidden = error.message === "Administrator access required";
    return json({ error: forbidden ? "Forbidden" : "Unauthorized" }, forbidden ? 403 : 401);
  }
  await ensureAdminTables(env);
  const rows = await env.DB.prepare(
    "SELECT r.uid, m.email, m.display_name, r.role, r.granted_by, r.granted_at, r.updated_at FROM admin_roles r LEFT JOIN member_directory m ON m.uid = r.uid ORDER BY CASE r.role WHEN 'super_admin' THEN 0 WHEN 'admin' THEN 1 ELSE 2 END, r.updated_at DESC"
  ).all();
  await recordAdminAction(env, adminUid, "view_admin_roles");
  return json({ roles: rows.results || [] });
}

async function createState(env, provider, userId) {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  const state = Array.from(bytes)
    .map(b => b.toString(16).padStart(2, "0"))
    .join("");
  const now = Math.floor(Date.now() / 1000);

  await env.DB.prepare("DELETE FROM oauth_states WHERE expires_at <= ?")
    .bind(now).run();

  await env.DB.prepare(
    "INSERT INTO oauth_states (state_hash, provider, user_id, expires_at, created_at) VALUES (?, ?, ?, ?, ?)"
  ).bind(await sha256(state), provider, userId, now + STATE_TTL, now).run();

  return state;
}

async function consumeState(env, provider, state) {
  if (!/^[a-f0-9]{64}$/.test(state || "")) return null;
  const now = Math.floor(Date.now() / 1000);
  return env.DB.prepare(
    "DELETE FROM oauth_states WHERE state_hash = ? AND provider = ? AND expires_at > ? RETURNING user_id"
  ).bind(await sha256(state), provider, now).first();
}

function requiredEnv(env, names) {
  return names.filter(name =>
    typeof env[name] !== "string" || env[name].trim() === ""
  );
}

function metaVersion(env) {
  const version = env.META_GRAPH_API_VERSION || "v27.0";
  if (!/^v\d+\.\d+$/.test(version)) {
    throw new Error("Invalid Meta Graph API version configuration");
  }
  return version;
}

function buildMetaAuthorizationUrl(env, state) {
  const url = new URL(
    "https://www.facebook.com/" + metaVersion(env) + "/dialog/oauth"
  );
  url.searchParams.set("client_id", env.META_APP_ID);
  url.searchParams.set("redirect_uri", env.META_REDIRECT_URI);
  url.searchParams.set("state", state);
  url.searchParams.set("response_type", "code");
  // The Login for Business configuration defines permissions and business assets.
  url.searchParams.set("config_id", env.META_LOGIN_CONFIG_ID);
  return url.toString();
}

async function getMetaAccessToken(env, code) {
  const endpoint = new URL(
    "https://graph.facebook.com/" + metaVersion(env) + "/oauth/access_token"
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
    throw new Error("Meta token exchange failed");
  }

  return {
    accessToken: result.access_token,
    expiresIn: typeof result.expires_in === "number" &&
      Number.isFinite(result.expires_in) ? result.expires_in : null,
    tokenType: typeof result.token_type === "string" ? result.token_type : "bearer"
  };
}

async function getMetaIdentity(env, accessToken) {
  const endpoint = new URL(
    "https://graph.facebook.com/" + metaVersion(env) + "/me"
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
    { name: "AES-GCM", iv: iv },
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
    "CREATE TABLE IF NOT EXISTS meta_connections (user_id TEXT PRIMARY KEY, meta_user_id TEXT NOT NULL, meta_name TEXT, token_ciphertext TEXT NOT NULL, token_iv TEXT NOT NULL, token_type TEXT NOT NULL DEFAULT 'bearer', expires_at INTEGER, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)"
  ).run();
}

function callbackPage(success) {
  const title = success ? "เชื่อมต่อ Meta สำเร็จ" : "เชื่อมต่อ Meta ไม่สำเร็จ";
  const message = success
    ? "บัญชีได้รับการเชื่อมต่อแล้ว คุณสามารถกลับไปยังแอป ADNEXA ได้"
    : "ไม่สามารถเชื่อมต่อบัญชีได้ กรุณากลับไปที่ ADNEXA แล้วลองใหม่อีกครั้ง";
  const html = "<!doctype html><html lang=\"th\"><meta charset=\"utf-8\">" +
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">" +
    "<title>" + title + "</title><body><main><h1>" + title +
    "</h1><p>" + message + "</p></main></body></html>";
  return new Response(html, {
    status: success ? 200 : 400,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
      "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'"
    }
  });
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
    "META_APP_SECRET",
    "META_LOGIN_CONFIG_ID",
    "META_REDIRECT_URI",
    "META_TOKEN_ENCRYPTION_KEY"
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

  if (!state) return callbackPage(false);
  const record = await consumeState(env, "meta", state);
  if (!record) return callbackPage(false);
  if (error || !code || code.length > 4096) return callbackPage(false);

  let stage = "configuration";
  try {
    const missing = requiredEnv(env, [
      "META_APP_ID",
      "META_APP_SECRET",
      "META_REDIRECT_URI",
      "META_TOKEN_ENCRYPTION_KEY"
    ]);
    if (missing.length) throw new Error("Missing Meta OAuth configuration");

    stage = "token_exchange";
    const token = await getMetaAccessToken(env, code);
    stage = "identity_verification";
    const identity = await getMetaIdentity(env, token.accessToken);
    stage = "token_encryption";
    const encrypted = await encryptToken(env, token.accessToken);
    stage = "database";
    await ensureMetaTable(env);

    const now = Math.floor(Date.now() / 1000);
    const expiresAt = token.expiresIn === null
      ? null
      : now + Math.max(0, token.expiresIn);

    await env.DB.prepare(
      "INSERT INTO meta_connections (user_id, meta_user_id, meta_name, token_ciphertext, token_iv, token_type, expires_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET meta_user_id = excluded.meta_user_id, meta_name = excluded.meta_name, token_ciphertext = excluded.token_ciphertext, token_iv = excluded.token_iv, token_type = excluded.token_type, expires_at = excluded.expires_at, updated_at = excluded.updated_at"
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

    return callbackPage(true);
  } catch {
    // Log only the stage. Never log OAuth codes, state, tokens, or secrets.
    console.error("Meta OAuth callback failed at stage:", stage);
    return callbackPage(false);
  }
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

  if (!row) return { response: json({ connected: false, provider: "meta" }) };

  if (row.expires_at !== null && row.expires_at <= Math.floor(Date.now() / 1000)) {
    return {
      response: json({
        connected: false,
        provider: "meta",
        reason: "token_expired"
      })
    };
  }
  return { userId: userId, row: row };
}

async function handleMetaConnection(request, env) {
  const result = await getAuthenticatedMetaConnection(request, env);
  if (result.response) return result.response;
  return json({
    connected: true,
    provider: "meta",
    account: { id: result.row.meta_user_id, name: result.row.meta_name },
    expires_at: result.row.expires_at
  });
}

async function handleMetaAdAccounts(request, env) {
  const connection = await getAuthenticatedMetaConnection(request, env);
  if (connection.response) return connection.response;

  let accessToken;
  try {
    accessToken = await decryptToken(env, connection.row);
  } catch {
    return json({ error: "Stored Meta credential unavailable" }, 503);
  }

  const cursor = new URL(request.url).searchParams.get("after");
  if (cursor !== null && (cursor.length === 0 || cursor.length > 2048)) {
    return json({ error: "Invalid pagination cursor" }, 400);
  }

  const endpoint = new URL(
    "https://graph.facebook.com/" + metaVersion(env) + "/me/adaccounts"
  );
  endpoint.searchParams.set("fields", "id,name,account_status,currency,timezone_name");
  endpoint.searchParams.set("limit", "100");
  endpoint.searchParams.set("access_token", accessToken);
  if (cursor !== null) endpoint.searchParams.set("after", cursor);

  const response = await fetch(endpoint.toString(), {
    headers: { "Accept": "application/json" }
  });
  const resultBody = await response.json().catch(() => ({}));

  const metaErrorCode = resultBody && resultBody.error &&
    Number(resultBody.error.code);
  const reauthorizationRequired =
    response.status === 401 || metaErrorCode === 190;

  if (!response.ok || !Array.isArray(resultBody.data)) {
    return json({
      error: "Unable to retrieve Meta ad accounts",
      reauthorization_required: reauthorizationRequired
    }, reauthorizationRequired ? 401 : 502);
  }

  const nextCursor = resultBody.paging &&
    resultBody.paging.cursors &&
    typeof resultBody.paging.cursors.after === "string"
      ? resultBody.paging.cursors.after
      : null;

  return json({
    provider: "meta",
    accounts: resultBody.data.map(account => ({
      id: account.id,
      name: account.name || null,
      status: account.account_status ?? null,
      currency: account.currency || null,
      timezone: account.timezone_name || null
    })),
    has_more: !!(resultBody.paging && resultBody.paging.next),
    next_cursor: nextCursor
  });
}

async function handleMetaInsights(request, env) {
  const connection = await getAuthenticatedMetaConnection(request, env);
  if (connection.response) return connection.response;

  const url = new URL(request.url);
  const rawAccountId = url.searchParams.get("ad_account_id") || "";
  const accountId = rawAccountId.replace(/^act_/, "");
  const datePreset = url.searchParams.get("date_preset") || "last_7d";
  const allowedPresets = new Set([
    "yesterday", "last_7d", "last_14d", "last_30d",
    "last_90d", "this_month", "last_month"
  ]);

  if (!/^\d{5,30}$/.test(accountId)) {
    return json({ error: "Invalid ad account ID" }, 400);
  }
  if (!allowedPresets.has(datePreset)) {
    return json({ error: "Unsupported reporting date range" }, 400);
  }

  let accessToken;
  try {
    accessToken = await decryptToken(env, connection.row);
  } catch {
    return json({ error: "Stored Meta credential unavailable" }, 503);
  }

  const endpoint = new URL(
    "https://graph.facebook.com/" + metaVersion(env) + "/act_" + accountId + "/insights"
  );
  endpoint.searchParams.set(
    "fields",
    "account_id,account_name,account_currency,spend,impressions,reach,clicks,ctr,cpc,cpm,frequency,date_start,date_stop"
  );
  endpoint.searchParams.set("level", "account");
  endpoint.searchParams.set("date_preset", datePreset);
  endpoint.searchParams.set("limit", "10");
  endpoint.searchParams.set("access_token", accessToken);

  const response = await fetch(endpoint.toString(), {
    headers: { "Accept": "application/json" }
  });
  const body = await response.json().catch(() => ({}));
  const metaErrorCode = body && body.error && Number(body.error.code);

  if (!response.ok || !Array.isArray(body.data)) {
    const reauthorizationRequired =
      response.status === 401 || metaErrorCode === 190;
    const permissionDenied = metaErrorCode === 10 || metaErrorCode === 200;
    return json({
      error: permissionDenied
        ? "Meta permission does not allow Insights access"
        : "Unable to retrieve Meta Insights",
      reauthorization_required: reauthorizationRequired
    }, reauthorizationRequired ? 401 : permissionDenied ? 403 : 502);
  }

  const row = body.data.length ? body.data[0] : null;
  return json({
    provider: "meta",
    level: "account",
    date_preset: datePreset,
    insights: row ? {
      account_id: row.account_id || accountId,
      account_name: row.account_name || null,
      account_currency: row.account_currency || null,
      spend: row.spend ?? "0",
      impressions: row.impressions ?? "0",
      reach: row.reach ?? "0",
      clicks: row.clicks ?? "0",
      ctr: row.ctr ?? "0",
      cpc: row.cpc ?? "0",
      cpm: row.cpm ?? "0",
      frequency: row.frequency ?? "0",
      date_start: row.date_start || null,
      date_stop: row.date_stop || null
    } : null
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
  await env.DB.prepare("DELETE FROM meta_connections WHERE user_id = ?")
    .bind(userId).run();

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

      if (method === "POST" && path === "/api/oauth/meta/start") {
        return await handleMetaStart(request, env);
      }

      if (method === "GET" && path === "/api/meta/callback") {
        return await handleMetaCallback(url, env);
      }

      if (method === "GET" && path === "/api/admin/overview") {
        return await handleAdminOverview(request, env);
      }
      if (method === "GET" && path === "/api/admin/connections") {
        return await handleAdminConnections(request, env);
      }
      if (method === "GET" && path === "/api/admin/audit") {
        return await handleAdminAudit(request, env);
      }

      if (method === "POST" && path === "/api/member/sync") {
        return await handleMemberSync(request, env);
      }
      if (method === "GET" && path === "/api/admin/access") {
        return await handleAdminAccess(request, env);
      }
      if (method === "GET" && path === "/api/admin/members") {
        return await handleAdminMembers(request, env);
      }
      if (method === "GET" && path === "/api/admin/roles") {
        return await handleAdminRoles(request, env);
      }
      const adminRoleMatch = path.match(/^\/api\/admin\/members\/([^/]+)\/role$/);
      if (method === "PUT" && adminRoleMatch) {
        return await handleAdminRoleUpdate(request, env, decodeURIComponent(adminRoleMatch[1]));
      }

      if (method === "GET" && path === "/api/meta/connection") {
        return await handleMetaConnection(request, env);
      }

      if (method === "GET" && path === "/api/meta/insights") {
        return await handleMetaInsights(request, env);
      }

      if (method === "GET" && path === "/api/meta/ad-accounts") {
        return await handleMetaAdAccounts(request, env);
      }

      if (method === "DELETE" && path === "/api/meta/connection") {
        return await handleMetaDisconnect(request, env);
      }

      // Keep TikTok's existing state-only placeholder unchanged for now.
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
          state: state,
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
        if (error) {
          return json({ provider: "tiktok", status: "authorization_denied" }, 400);
        }
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
