# CONTENTNEX API Worker

Cloudflare Worker source for the CONTENTNEX backend.

## Dedicated resources

- Worker: `contentnex-api`
- D1 database: `contentnex-db`, bound as `ADMIN_DB`
- Admin Firebase project: `contentnex-admin`
- Customer Firebase project for customer API authentication: `adnexa-8daea`

CONTENTNEX D1 storage is separate from ADNEXA's `adnexa-auth-db`. The Worker configuration is in `wrangler.toml`.

## Current implementation

- `GET /v1/health`: public service health response.
- `GET /v1/admin/access-check`: verifies a Firebase ID token from `ADMIN_FIREBASE_PROJECT_ID` and grants access only when the verified token contains `contentnexRole: "super_admin"`.
- `GET /v1/admin/audit-logs`: reads audit events from `ADMIN_DB`, after the same admin authentication check.
- `POST /v1/ai/generate`: validates a customer Firebase ID token, request shape, task allowlist, and explicit external-AI consent. It intentionally returns `AI_PROVIDER_DISABLED` after validation.
- Firebase ID token verification checks RS256 signature against Google's published Firebase Secure Token keys, issuer, audience, expiry, subject, and verified email.

## Local checks

Requires Node.js and npm. From this directory:

```sh
npm install
npm test
npm run dev
```

No paid service is needed for local tests. Installing Wrangler is a development dependency only.

## Admin identity

The dedicated admin Firebase project is `contentnex-admin`. The admin bootstrap procedure and claim assignment must target this project only. Never assign CONTENTNEX administrator claims in the customer Firebase project. Never place credentials in GitHub, source code, the APK, or this chat.

## Before deployment

1. Confirm Firebase project IDs match the separate customer and admin app configurations.
2. Confirm `contentnex-api` is bound to `contentnex-db`.
3. Apply the D1 migration only after explicit owner approval.
4. Configure an exact `APP_ORIGIN` only if a browser client is used.
5. Review Cloudflare account limits and pricing; do not enable paid plans or add a payment method.
6. Deploy only after backend tests pass and the owner explicitly approves the deployment target.
7. Verify `/v1/health` and admin access-check after deployment.
8. Do not enable Gemini until free quota, provider data-use terms, user consent UX, server-side secret storage, request limits, and a kill switch have been reviewed.

## Deliberate limitations

- Gemini is not called and no prompt is forwarded to Google.
- Admin management APIs, account management, and live metrics are not implemented.
- Token revocation checking is not implemented yet.
- This Worker does not create, edit, or publish ad campaigns.
- No API key or privileged secret is present in this repository.
