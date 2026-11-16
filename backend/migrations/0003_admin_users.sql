-- CONTENTNEX admin directory and allowlist.
-- Apply only to the dedicated contentnex-db after explicit approval.
CREATE TABLE IF NOT EXISTS admin_users (
  uid TEXT PRIMARY KEY NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'admin', 'support')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
  created_at INTEGER NOT NULL,
  created_by TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_admin_users_status_role
  ON admin_users(status, role);

-- Bootstrap the already verified CONTENTNEX Super Admin account.
INSERT OR IGNORE INTO admin_users (uid, role, status, created_at, created_by)
VALUES (
  'UPneGl7xwHUXQAAX2wqtJQC9hoJ2',
  'super_admin',
  'active',
  unixepoch(),
  'SYSTEM_BOOTSTRAP'
);
