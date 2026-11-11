# ADNEXA ADMIN

A separate Flutter Android app for trusted ADNEXA administrators.

## First release
- Separate application from customer-facing ADNEXA ADS.
- Email/password sign-in only; no public registration.
- Requires verified email and Firebase custom claim `admin: true` or `role: "admin"`.
- Reads existing Worker endpoints: `/api/admin/overview`, `/api/admin/connections`, and `/api/admin/audit`.
- Server independently verifies the Firebase ID token and admin claim.
- Read-only overview, Meta connection metadata, and recent admin audit events.
- Member directory populated by verified customer sign-ins through the Worker profile-sync endpoint.
- Server-verified role levels: super administrator, administrator, support, and customer.
- Only the super administrator can grant or revoke administrator/support roles. Self-role changes and changes to the super-administrator account are blocked.
- No account suspension/deletion, campaign operations, or ad spending.

## Firebase
Uses existing project `adnexa-8daea` and the repository Actions variables: `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`.
Register a separate Android app in Firebase project `adnexa-8daea` with package name `com.adnexa.admin`. Store its Firebase App ID as the GitHub Actions repository variable `ADMIN_FIREBASE_APP_ID`. The shared API key, sender ID, and project ID continue to use the existing repository variables. The admin APK can compile before registration, but Firebase sign-in will remain unavailable until this App ID is configured. Never include service-account credentials in the mobile app or repository.

## Build
Run `flutter pub get`, `flutter analyze`, `flutter test`, `flutter create . --platforms=android --org com.adnexa --project-name admin`, then `flutter build apk --release` from this directory.

## Member management rollout

The admin app checks access through `GET /api/admin/access`; the Worker validates the Firebase token and the D1 role registry. The first trusted Firebase custom claim `admin: true` is bootstrapped as `super_admin`. New customer records appear after the customer has verified their email and signs in with an app build containing the member-sync call. Existing users are not bulk-imported.

Role changes are stored in the existing D1 database and audited. This release intentionally does not disable Firebase Authentication accounts or modify other users' Firebase custom claims. Account suspension/deletion requires a separately reviewed Firebase Admin SDK integration.
