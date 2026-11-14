# CONTENTNEX Admin System — Security-First Design

## Purpose
Provide a separate operational workspace for CONTENTNEX administrators without exposing customer data or privileged actions to ordinary accounts.

## Shared Firebase project boundary
CONTENTNEX currently shares Firebase project `adnexa-8daea` with ADNEXA. To avoid accidentally granting privileges in another application, CONTENTNEX uses only the namespaced Firebase Custom Claim `contentnexRole`. It does not read a generic `role` claim.

- `customer`: default role.
- `support`: limited support access; no billing, credentials, or campaign publishing permissions.
- `super_admin`: CONTENTNEX operational owner role. This claim is scoped to CONTENTNEX and does not imply an ADNEXA role.

No user may promote themselves through a client-side field, local preference, request body, or editable Firestore document.

## Trusted role assignment
- Firebase Authentication remains the identity provider.
- A trusted server-side administrative process assigns `contentnexRole: "super_admin"`.
- The bootstrap utility verifies the configured project, exact UID, exact email, and verified-email status before changing claims.
- Existing unrelated custom claims are preserved.
- The backend verifies Firebase ID token signature, issuer, audience, expiry, verified email, and the CONTENTNEX-specific claim.
- Client UI visibility is convenience only; every privileged API and database operation independently checks authorization.
- Never ship an admin UID, password, service-account key, or bootstrap secret in the APK or repository.

## Access boundaries
- Customer: own account and own content only.
- Support: limited account lookup and support notes; no access to private content by default.
- Super Admin: explicitly allowlisted operational endpoints. No unrestricted database console exposed through the mobile app.
- Backend: deny by default; validate token, role, resource ownership, request schema, and action-specific permission on every request.

## Admin workspace modules (phased)
1. Overview: service health, account totals, recent operational events. No fabricated production metrics.
2. User management: search accounts, view verification/status, suspend/reactivate with reason and audit event.
3. Content moderation: only introduce after a documented privacy basis and explicit permission model. Private customer drafts are not visible to support by default.
4. Integration status: display Meta/TikTok connection health without revealing access tokens or secrets.
5. Audit log: actor, action, target, timestamp, outcome, and reason; append-only from the application perspective.
6. Configuration: non-secret feature flags and safe limits. Secrets remain in backend secret storage.

## High-impact actions
- Require a clear confirmation screen and reason.
- Use idempotency keys for retryable backend operations.
- Record successful and rejected attempts in audit logs.
- Never publish, edit, or spend on real ad campaigns during prototype testing.
- No payment handling or refunds until a separate threat model and approval are complete.

## Data and infrastructure
- Firestore Security Rules must enforce customer ownership and deny unknown paths.
- Server-side admin operations use least-privilege service identities.
- Admin endpoints verify token signature, issuer, audience, expiry, verified email, and the CONTENTNEX-specific role claim.
- Add rate limits, structured error responses, monitoring, and automated authorization tests before deploying management endpoints.
- Do not enable Firebase/Cloud billing or paid services without explicit owner approval.

## Release gates
1. Approve the role matrix and admin capabilities.
2. Implement server-side role verification and negative authorization tests.
3. Add Firestore rules and emulator tests; prove customers cannot read or mutate another customer's records.
4. Connect an admin-only UI that stays unavailable to customer accounts.
5. Review audit logging, data minimization, and recovery procedures.
6. Deploy only after tests pass and the owner explicitly approves the target.

## Current implementation status (2026-11-15)
- Worker source contains a fail-closed `/v1/admin/access-check` route that reads only `contentnexRole`.
- Generic Firebase claims such as `role: "admin"` do not grant CONTENTNEX access.
- A secure, owner-run bootstrap utility is documented separately; it has not been run.
- No custom claim has been assigned, Worker has not been deployed, and no live admin API or database-backed audit log exists.
- The Admin Control Center remains a UI prototype with unavailable metrics and no privileged operations.
