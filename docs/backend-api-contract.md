# CONTENTNEX Backend API Contract (design only)

Status: **specification only**. No backend service is deployed and no endpoint in this document is live.

## Goals

- Provide one authenticated boundary between the Flutter app and AI providers.
- Keep provider credentials on the server; never ship them in Dart, assets, logs, or APKs.
- Enforce customer/admin authorization on the server.
- Keep AI output as an unapproved draft until the user reviews it.
- Fail closed when authentication, quota, privacy consent, or provider configuration is missing.

## Proposed routes

### `GET /v1/health`

A minimal operational check. It must not expose secrets, environment variables, account data, or internal stack traces.

Example response:

```json
{
  "status": "ok",
  "service": "contentnex-api",
  "version": "0.1.0"
}
```

This route is public and returns no user-specific information.

### `POST /v1/ai/generate`

Requires a valid Firebase ID token:

`Authorization: Bearer <Firebase-ID-token>`

The server must verify the token signature, issuer, audience, expiry, and project before processing. A client-supplied user ID or role is never trusted.

Example request:

```json
{
  "task": "copywriter",
  "prompt": "Create three Thai product captions for ...",
  "languageCode": "th",
  "context": {
    "productCategory": "food"
  },
  "consent": {
    "externalAiProcessing": true
  }
}
```

Validation:
- `task`: required, allowlisted identifier; maximum 64 characters.
- `prompt`: required, non-empty, bounded length (initial proposal: 12,000 characters).
- `languageCode`: optional BCP-47 language tag; default `th`.
- `context`: optional string-to-string map; bounded key count and value length.
- `consent.externalAiProcessing`: must be explicitly true before sending content to an external provider.
- Reject unknown or malformed fields rather than silently accepting unsafe input.

Example success response:

```json
{
  "requestId": "server-generated-id",
  "status": "draft",
  "providerRoute": "gemini_api",
  "output": "Generated draft text...",
  "requiresUserReview": true
}
```

The provider route in this response is descriptive metadata, not a credential or a promise that a route is enabled.

Error response shape:

```json
{
  "error": {
    "code": "AI_PROVIDER_UNAVAILABLE",
    "message": "AI service is temporarily unavailable.",
    "retryable": true
  }
}
```

Do not return raw provider errors, prompts, tokens, secrets, stack traces, or internal infrastructure details.

## Security requirements

1. Verify Firebase ID tokens on every private request.
2. Derive the user identity from the verified token only.
3. Enforce role and ownership checks on the server; UI hiding is not authorization.
4. Apply per-user rate limits, request-size limits, timeouts, and abuse controls.
5. Never log authorization headers, API keys, full prompts, or sensitive context.
6. Do not store prompts or outputs by default. If persistence is added, document retention and deletion.
7. Treat model output as untrusted text. Do not execute it as code or instructions.
8. No ad account mutation, campaign publishing, or ad spend through this endpoint.
9. Use HTTPS only and restrict CORS to the production app/web origins when those are known.
10. Keep secrets in the backend secret manager/environment configuration, never in Git.

## Initial role model

- `customer`: may access only their own content and allowed AI tasks.
- `admin`: may access explicitly authorized administrative operations.
- New accounts default to customer privileges.
- Never allow a client to self-assign admin.
- Admin claims/roles must be granted through a trusted administrative process.

## Not included in this phase

- No deployed API, database, admin console, AI provider, OAuth token storage, billing, or ad publishing.
- No assumption that Firebase Authentication alone creates a backend authorization layer.
- No API key, billing account, or paid resource is created by this specification.
