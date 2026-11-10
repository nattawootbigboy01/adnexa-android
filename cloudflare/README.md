# ADNEXA Cloudflare Worker — Meta OAuth

This Worker source is kept separately from the Flutter Android app. It does not publish ads or spend money.

## Required Cloudflare bindings and secrets

Keep the existing D1 binding:

- `DB` — existing D1 database `adnexa-auth-db`

Add these Worker secrets/variables in Cloudflare Dashboard → Workers & Pages → `adnexa-api` → Settings → Variables and Secrets:

| Name | Type | Value |
|---|---|---|
| `META_APP_ID` | Variable | Meta app ID |
| `META_LOGIN_CONFIG_ID` | Variable | Facebook Login for Business configuration ID |
| `META_REDIRECT_URI` | Variable | `https://adnexa-api.nattawootbigboy01.workers.dev/api/meta/callback` |
| `META_GRAPH_API_VERSION` | Variable | `v25.0` (confirm supported version in Meta dashboard before production) |
| `META_APP_SECRET` | Secret | Meta app secret |
| `META_TOKEN_ENCRYPTION_KEY` | Secret | Base64 encoding of exactly 32 cryptographically random bytes |

Never put `META_APP_SECRET` or `META_TOKEN_ENCRYPTION_KEY` in Flutter, GitHub source, screenshots, or chat messages. Do not reuse the Meta App Secret as the encryption key.

The Worker creates the `meta_connections` table in the existing D1 database on first use. Existing `oauth_states` data and the TikTok placeholder flow are retained.

## Meta Developer Dashboard

1. Confirm the app has the Marketing API use case/product.
2. Configure Facebook Login for Business and create a Login Configuration.
3. Configure the Login Configuration with the minimum assets and permissions needed for the intended workflow. For read-only discovery, request only the approved read permissions. Add `ads_management` only when the product is ready to create/manage campaigns and Meta has approved the required access.
4. Set the configuration's access-token type deliberately; this implementation stores the token returned by the authorization-code exchange and does not assume its lifetime.
5. Add the exact redirect URI above to the valid OAuth redirect URI allowlist.
6. Complete any required App Review, business verification, and Marketing API access requirements before inviting external customers.

The Login Configuration controls the permissions/assets for Facebook Login for Business; this Worker sends its `config_id` and does not hard-code a duplicate `scope` list.

## Endpoints

All endpoints except the OAuth callback and health endpoints require a Firebase ID token in `Authorization: Bearer <Firebase ID Token>`.

- `POST /api/oauth/meta/start` — creates one-time state and returns `authorization_url`.
- `GET /api/meta/callback` — consumes state, exchanges code server-side, verifies the Meta identity, and encrypts the token at rest.
- `GET /api/meta/connection` — returns connection status and non-secret account identity.
- `GET /api/meta/ad-accounts` — read-only list of ad accounts visible to the connected Meta identity.
- `DELETE /api/meta/connection` — removes the locally stored encrypted token.

The Flutter app must open the returned `authorization_url` in the system browser, then poll `GET /api/meta/connection` after the callback. Access tokens are never returned to the app.

## Security and rollout notes

- AES-256-GCM encrypts access tokens before they are written to D1. A unique 96-bit IV is generated for every encryption.
- OAuth state is random, stored as a SHA-256 hash, expires after 10 minutes, and is consumed once.
- The callback response does not echo Meta error text, authorization codes, state values, or tokens.
- The current endpoint set is for account connection and read-only account discovery. It contains no campaign create, edit, pause, or publish operation.
- Disconnect deletes the locally stored token. It does not claim to revoke the token at Meta.
- Token expiry is recorded when Meta supplies `expires_in`; the implementation does not silently extend tokens.
- Before production, run end-to-end tests with an app-role/test user and verify the exact Login Configuration behavior, token type, granted permissions, and account list response.
- This source has not been deployed to Cloudflare or tested against Meta in this change.
