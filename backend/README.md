# CONTENTNEX API Worker

Cloudflare Worker source for the planned CONTENTNEX backend.

## Current implementation

- `GET /v1/health`: public service health response.
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

## Before any deployment

1. Confirm the Firebase project ID matches the app's Firebase configuration.
2. Configure an exact `APP_ORIGIN` if a browser client is used.
3. Review Cloudflare account limits and pricing; do not enable paid plans or add a payment method.
4. Deploy only after the owner explicitly approves deployment.
5. Verify `/v1/health` after deployment.
6. Do not enable Gemini until free quota, provider data-use terms, user consent UX, server-side secret storage, request limits, and a kill switch have been reviewed.

## Deliberate limitations

- Gemini is not called and no prompt is forwarded to Google.
- No user data is persisted.
- No admin role or content database is implemented yet.
- This Worker does not create, edit, or publish ad campaigns.
- No API key or other secret is present in this repository.
