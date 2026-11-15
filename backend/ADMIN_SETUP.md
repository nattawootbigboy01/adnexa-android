# CONTENTNEX Admin Backend Setup

This change adds a protected, read-only admin audit-log API. It does not deploy the Worker or create Cloudflare resources.

## Required Cloudflare D1 database

Create a **new, dedicated** D1 database named `contentnex-admin-db`. Do not reuse ADNEXA's `adnexa-auth-db`.

After creating it, bind it to this Worker as `ADMIN_DB` in `backend/wrangler.toml`:

```toml
[[d1_databases]]
binding = "ADMIN_DB"
database_name = "contentnex-admin-db"
database_id = "REPLACE_WITH_THE_NEW_DATABASE_ID"
migrations_dir = "migrations"
```

Apply the schema from the `backend` directory:

```bash
npx wrangler d1 migrations apply contentnex-admin-db --remote
```

Do not deploy until the binding contains the actual new database ID and the migration succeeds.

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
