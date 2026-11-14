# CONTENTNEX API Worker

Cloudflare Worker source for the planned CONTENTNEX backend.

## Current implementation

- `GET /v1/health`: public service health response.
- `GET /v1/admin/access-check`: verifies a Firebase ID token and grants access only when the verified token contains `contentnexRole: "super_admin"`.
- `POST /v1/ai/generate`: validates a Firebase ID token, request shape, task allowlist, and explicit external-AI consent. It intentionally returns `AI_PROVIDER_DISABLED` after validation.
- Firebase ID token verification checks RS256 signature against Google's published Firebase Secure Token keys, issuer, audience, expiry, subject, and verified email.
- Worker name is `contentnex-api`, separate from any ADNEXA Worker.

## Local checks

Requires Node.js and npm. From this directory:

```sh
npm install
npm test
npm run dev
```

No paid service is needed for local tests. Installing Wrangler is a development dependency only.

## Super Admin bootstrap

The shared Firebase project is `adnexa-8daea`. CONTENTNEX uses the namespaced custom claim `contentnexRole` so a generic `role` claim used by ADNEXA or another app cannot grant CONTENTNEX access.

Use the owner-controlled bootstrap procedure in [tools/admin-bootstrap/README.md](../tools/admin-bootstrap/README.md). It verifies the exact Firebase UID, email, and verified-email status before adding only `contentnexRole: "super_admin"`, preserving other custom claims. Run it only in a trusted Google Cloud Shell session signed in as the project owner. Never place credentials in GitHub, source code, the APK, or this chat.

## Before any deployment

1. Confirm the Firebase project ID matches the app's Firebase configuration.
2. Configure an exact `APP_ORIGIN` if a browser client is used.
3. Review Cloudflare account limits and pricing; do not enable paid plans or add a payment method.
4. Deploy only after tests pass and the owner explicitly approves the deployment target.
5. Verify `/v1/health` and the admin access-check after deployment.
6. Do not enable Gemini until free quota, provider data-use terms, user consent UX, server-side secret storage, request limits, and a kill switch have been reviewed.

## Deliberate limitations

- Gemini is not called and no prompt is forwarded to Google.
- No user data is persisted.
- The admin access-check returns only an authorization result and does not expose account data.
- Admin management APIs, database-backed audit storage, and live metrics are not implemented.
- This Worker does not create, edit, or publish ad campaigns.
- No API key or other secret is present in this repository.
