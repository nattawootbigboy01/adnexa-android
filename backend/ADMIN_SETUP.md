# CONTENTNEX Admin Backend Setup

This change adds a protected, read-only admin audit-log API. It does not deploy the Worker or create Cloudflare resources.

## Reuse the existing ADNEXA D1 database

Use the existing Cloudflare D1 database named `adnexa-auth-db`. Do not create a second database.

The CONTENTNEX Worker can bind to the same D1 database while keeping its audit data in a separate table named `admin_audit_logs`. The existing ADNEXA OAuth table `oauth_states` is not modified by this migration.

Add this binding to `backend/wrangler.toml`, replacing the placeholder with the actual D1 database ID shown in Cloudflare Dashboard:

```toml
[[d1_databases]]
binding = "ADMIN_DB"
database_name = "adnexa-auth-db"
database_id = "REPLACE_WITH_EXISTING_ADNEXA_AUTH_DB_ID"
migrations_dir = "migrations"
```

Do not deploy while the database ID is still a placeholder. The database ID must be copied from the existing `adnexa-auth-db` database details page, not guessed.

From the `backend` directory, apply the migration to the existing remote database:

```bash
npx wrangler d1 migrations apply adnexa-auth-db --remote
```

This applies the new `admin_audit_logs` table and its indexes. It must not drop, rename, or alter the existing `oauth_states` table.

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
