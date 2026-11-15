# CONTENTNEX Admin Backend Setup

This change adds a protected, read-only admin audit-log API and a separate admin app scaffold. Admin API authentication must use a dedicated Firebase project through `ADMIN_FIREBASE_PROJECT_ID`; customer API authentication continues to use `FIREBASE_PROJECT_ID`. It does not deploy the Worker or create Firebase/Cloudflare resources.

## Reuse the existing ADNEXA D1 database

Use the existing Cloudflare D1 database named `adnexa-auth-db`. Do not create a second database.

The CONTENTNEX Worker can bind to the same D1 database while keeping its audit data in a separate table named `admin_audit_logs`. The existing ADNEXA OAuth table `oauth_states` is not modified by this migration.

Add this binding to `backend/wrangler.toml`, using the verified D1 database ID:

```toml
[[d1_databases]]
binding = "ADMIN_DB"
database_name = "adnexa-auth-db"
database_id = "e6d29a02-a710-4ce4-87f9-4701224201ee"
migrations_dir = "migrations"
```

The binding has been added to `backend/wrangler.toml` using the database ID supplied by the user. Confirm the ID in Cloudflare before applying the remote migration.

From the `backend` directory, apply the migration to the existing remote database:

```bash
npx wrangler d1 migrations apply adnexa-auth-db --remote
```

This applies the new `admin_audit_logs` table and its indexes. It must not drop, rename, or alter the existing `oauth_states` table.

## Separate administrator Firebase project

Create a dedicated Firebase project for CONTENTNEX ADMIN. Register only the admin Android app in that project and configure its Firebase Auth email/password provider. Do not enable public admin registration. Provision the approved administrator account and assign the CONTENTNEX `contentnexRole=super_admin` claim in that project only. Then set the Cloudflare Worker variable `ADMIN_FIREBASE_PROJECT_ID` to that project's exact project ID. Until this variable is configured, admin endpoints intentionally return `ADMIN_AUTH_NOT_CONFIGURED` (503). The admin app reads its own Firebase settings from `ADMIN_FIREBASE_API_KEY`, `ADMIN_FIREBASE_APP_ID`, `ADMIN_FIREBASE_MESSAGING_SENDER_ID`, and `ADMIN_FIREBASE_PROJECT_ID` build-time values. Do not reuse the customer app's Firebase configuration for the final admin release.

## API

- `GET /v1/health`: reports whether the D1 binding is present.
- `GET /v1/admin/access-check`: verifies the Firebase ID token and the CONTENTNEX-only `contentnexRole=super_admin` claim. If D1 is configured, it records a successful access-check event.
- `GET /v1/admin/audit-logs?limit=50`: returns the latest audit events. Requires a verified Firebase ID token with the CONTENTNEX super-admin claim and a configured D1 binding. The limit is clamped to 1–100.

Audit records store the Firebase UID, action, outcome, resource type, optional resource ID, JSON details, and Unix timestamp. They do not store ID tokens, passwords, email addresses, or IP addresses.

## Current safety limits

- No user deletion, role changes, content edits, moderation actions, or payment operations are exposed.
- No Gemini provider is enabled.
- No Worker deployment or Cloudflare database creation is performed by this source change.
- Admin access is checked by the Worker, not trusted from client-supplied role fields.
