# CONTENTNEX Admin System — Security-First Design

## Purpose
Provide a separate operational workspace for CONTENTNEX administrators without exposing customer data or privileged actions to ordinary accounts.

This document is a design specification only. It does not create production admin privileges, change Firebase users, deploy a backend, or enable campaign operations.

## Roles
- `customer`: default role. Can manage only their own profile, drafts, and permitted workspace data.
- `support`: limited support access. Read only the minimum customer/account metadata needed for support; no billing, credential, or campaign publishing permissions.
- `admin`: operational administration, user status management, service configuration, and audit review. High-impact actions require confirmation and an audit record.

No user may promote themselves or another user through a client-side field, local preference, request body, or editable Firestore document.

## Trusted role assignment
- Firebase Authentication remains the identity provider.
- A trusted server-side administrative process assigns Firebase Custom Claims.
- The backend verifies Firebase ID tokens and reads role claims from the verified token.
- Client UI visibility is convenience only; every privileged API and database operation independently checks authorization.
- Initial admin bootstrap must be performed manually by the project owner through a trusted server environment. Never ship an admin UID, password, service-account key, or bootstrap secret in the APK or repository.

## Access boundaries
- Customer: own account and own content only.
- Support: limited account lookup and support notes; no access to private content by default.
- Admin: explicitly allowlisted operational endpoints. No unrestricted database console exposed through the mobile app.
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
- Admin endpoints must verify Firebase token signature, issuer, audience, expiration, email verification where required, and role claim.
- Add rate limits, structured error responses, monitoring, and automated authorization tests before deployment.
- Do not enable Firebase/Cloud billing or paid services without explicit owner approval.

## Release gates
1. Approve the role matrix and admin capabilities.
2. Implement server-side role verification and negative authorization tests.
3. Add Firestore rules and emulator tests; prove customers cannot read or mutate another customer's records.
4. Add an admin-only UI that remains unavailable to customer accounts.
5. Review audit logging, data minimization, and recovery procedures.
6. Deploy only after separate explicit approval.

## Current status
- A prototype `/v1/admin/access-check` route and fail-closed role-claim reader exist in Worker source; they are not deployed.
- No admin custom claims have been assigned.
- No admin management APIs, user lookup, suspension, audit storage, or admin UI exist.
- This design does not grant any account additional privileges.
