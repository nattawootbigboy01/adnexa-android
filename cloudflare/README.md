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
| `META_GRAPH_API_VERSION` | Variable | `v27.0` (current version announced by Meta; verify support in the app's dashboard before production) |
| `META_APP_SECRET` | Secret | Meta app secret |
| `META_TOKEN_ENCRYPTION_KEY` | Secret | Base64 encoding of exactly 32 cryptographically random bytes |

Never put `META_APP_SECRET` or `META_TOKEN_ENCRYPTION_KEY` in Flutter, GitHub source, screenshots, or chat messages. Do not reuse the Meta App Secret as the encryption key.

The Worker creates the `meta_connections` table in the existing D1 database on first use. Existing `oauth_states` data and the TikTok placeholder flow are retained.

## Meta Developer Dashboard

1. Confirm the app has the Marketing API use case/product.
2. Configure Facebook Login for Business and create a Login Configuration.
3. Configure the Login Configuration with the minimum assets and permissions needed for the intended workflow. For account discovery and Insights reporting, verify that the user grant includes `ads_read` and that Meta has approved the required access. Do not request `ads_management` for this read-only phase; add it only in a later, separately reviewed campaign-management phase.
4. Set the configuration's access-token type deliberately; this implementation stores the token returned by the authorization-code exchange and does not assume its lifetime.
5. Add the exact redirect URI above to the valid OAuth redirect URI allowlist.
6. Complete any required App Review, business verification, and Marketing API access requirements before inviting external customers.

The Login Configuration controls the permissions/assets for Facebook Login for Business; this Worker sends its `config_id` and does not hard-code a duplicate `scope` list.

## Endpoints

All endpoints except the OAuth callback and health endpoints require a Firebase ID token in `Authorization: Bearer <Firebase ID Token>`.

- `POST /api/oauth/meta/start` — creates one-time state and returns `authorization_url`.
- `GET /api/meta/callback` — consumes state, exchanges code server-side, verifies the Meta identity, and encrypts the token at rest.
- `GET /api/meta/connection` — returns connection status and non-secret account identity.
- `GET /api/meta/ad-accounts` — read-only list of up to 100 ad accounts per request. If `has_more` is true and `next_cursor` is present, request the next page with `?after=<URL-encoded next_cursor>`. The Worker accepts only the opaque cursor (not a caller-supplied URL) and returns the same account fields for each page.
- `GET /api/meta/insights?ad_account_id=<numeric-id>&date_preset=last_7d` — read-only account-level performance summary. Supported presets: `yesterday`, `last_7d`, `last_14d`, `last_30d`, `last_90d`, `this_month`, and `last_month`. Returns spend, impressions, reach, clicks, CTR, CPC, CPM, frequency, currency, and reporting dates. Requires the connected user to have the necessary approved read permission (normally `ads_read`).
- `DELETE /api/meta/connection` — removes the locally stored encrypted token.
- `GET /api/admin/overview` — administrator-only, read-only connection counts and current D1 role capabilities. Requires a verified Firebase ID token and a role accepted by the server-side D1 registry. The initial trusted Firebase custom claim `admin: true` bootstraps the first `super_admin`.
- `GET /api/admin/connections` — administrator-only list of Meta connection metadata (UID and Meta account identity only; no tokens). Requires a verified email and a server-approved D1 role.
- `GET /api/admin/audit` — administrator-only recent admin access events.
- `POST /api/member/sync` — called by the customer app after a verified user signs in. It records only that user's UID, verified email, display name, and last-seen timestamp in D1. It cannot write another user's profile.
- `GET /api/admin/access` — returns the caller's server-verified D1 role and capabilities.
- `GET /api/admin/members?limit=50&search=<text>` — administrator-only member directory (maximum 100 rows per request).
- `GET /api/admin/roles` — administrator-only role assignments.
- `PUT /api/admin/members/<uid>/role` — super-administrator-only role update. Allowed values are `customer`, `support`, and `admin`. The `super_admin` role cannot be granted or changed through this endpoint, and an administrator cannot change their own role.

### Member directory and role controls

The member directory is populated when a verified customer signs in with a version of the app that includes the profile-sync call. Existing customers appear after their next successful sign-in; this is not an immediate full export of Firebase Authentication users.

The existing Firebase custom claim `admin: true` is bootstrapped as the initial `super_admin` in the D1 `admin_roles` table. After bootstrap, D1 is the server-side source of truth for console roles. Roles are `super_admin`, `admin`, and `support`; ordinary customers have no row and are treated as `customer`. Only a super administrator can grant or revoke `admin` and `support` roles. Role changes are written to the admin audit log and a detail table.

This release does not disable Firebase Authentication accounts, suspend sign-in, delete accounts, or alter Firebase custom claims for other users. Those actions require a separately reviewed Firebase Admin SDK integration. It also does not create, edit, pause, publish, or spend on campaigns. Keep the existing D1 binding `DB` pointed at `adnexa-auth-db`; no new secret or paid service is required.

The Flutter app must open the returned `authorization_url` in the system browser, then poll `GET /api/meta/connection` after the callback. Access tokens are never returned to the app.

## Security and rollout notes

- AES-256-GCM encrypts access tokens before they are written to D1. A unique 96-bit IV is generated for every encryption.
- OAuth state is random, stored as a SHA-256 hash, expires after 10 minutes, and is consumed once.
- The callback response does not echo Meta error text, authorization codes, state values, or tokens.
- The current endpoint set is for account connection, read-only account discovery, and read-only account-level Insights. It contains no campaign create, edit, pause, or publish operation.
- Disconnect deletes the locally stored token. It does not claim to revoke the token at Meta.
- Token expiry is recorded when Meta supplies `expires_in`; the implementation does not silently extend tokens.
- Before production, run end-to-end tests with an app-role/test user and verify the exact Login Configuration behavior, token type, granted permissions, and account list response.
- This source has not been deployed to Cloudflare or tested against Meta in this change.
