CREATE TABLE IF NOT EXISTS admin_token_revocations (
  uid TEXT PRIMARY KEY NOT NULL,
  revoked_after INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
