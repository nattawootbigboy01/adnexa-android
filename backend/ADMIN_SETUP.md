# CONTENTNEX Admin Backend Setup

CONTENTNEX uses a dedicated Cloudflare Worker, a dedicated D1 database, and a dedicated Firebase project for administrator authentication. The customer Firebase project remains separate. This setup documentation does not deploy the Worker or apply database migrations.

## Dedicated Cloudflare resources

- Worker: `contentnex-api`
- D1 database: `contentnex-db`
- D1 binding: `ADMIN_DB`
- Admin Firebase project: `contentnex-admin`
- Admin Android package: `com.contentnex.contentnex_admin`

The D1 database ID is configured in `backend/wrangler.toml`. Keep the CONTENTNEX audit records in this database. Do not point this Worker at ADNEXA's `adnexa-auth-db`.

From the `backend` directory, the remote migration command (do not run until explicitly approved) is:

```bash
npx wrangler d1 migrations apply contentnex-db --remote
```

The migration creates only `admin_audit_logs` and its indexes in `contentnex-db`. It does not modify ADNEXA's database.

## Firebase separation

- Customer Firebase project: `adnexa-8daea`, used only for customer API authentication.
- Admin Firebase project: `contentnex-admin`, used for `ADMIN_FIREBASE_PROJECT_ID` and the separate admin Android app.

The admin project must have Email/Password authentication enabled. Do not enable public admin registration. Provision the approved administrator account through an owner-controlled process and assign `contentnexRole=super_admin` only in `contentnex-admin`. Require verified email. Do not reuse customer Firebase configuration for the final admin release.

The admin app build expects `ADMIN_FIREBASE_API_KEY`, `ADMIN_FIREBASE_APP_ID`, `ADMIN_FIREBASE_MESSAGING_SENDER_ID`, `ADMIN_FIREBASE_PROJECT_ID`, and `ADMIN_API_BASE_URL` as repository variables. These are build configuration values; never put service-account private keys or privileged secrets in the APK.

## API

- `GET /v1/health`: reports Worker and configuration status.
- `GET /v1/admin/access-check`: verifies a Firebase ID token from the dedicated admin project and requires the CONTENTNEX-only `contentnexRole=super_admin` claim. If D1 is configured, it writes an access event.
- `GET /v1/admin/audit-logs?limit=50`: returns the latest audit events, requiring the same super-admin check and configured D1 binding. Limit is clamped to 1–100.

## Current safety limits

- No user deletion, role changes, content edits, moderation actions, or payment operations are exposed.
- No Gemini provider is enabled; AI generation deliberately returns `AI_PROVIDER_DISABLED`.
- No Worker deployment or D1 migration is performed by this documentation change.
- Admin access is checked by the Worker, not trusted from client-supplied role fields.
- Token revocation checking is not implemented yet; do not treat this backend as production-ready until that limitation is addressed and reviewed.
