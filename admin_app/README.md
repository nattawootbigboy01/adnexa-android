# ADNEXA ADMIN

A separate Flutter Android app for trusted ADNEXA administrators.

## First release
- Separate application from customer-facing ADNEXA ADS.
- Email/password sign-in only; no public registration.
- Requires verified email and Firebase custom claim `admin: true` or `role: "admin"`.
- Reads existing Worker endpoints: `/api/admin/overview`, `/api/admin/connections`, and `/api/admin/audit`.
- Server independently verifies the Firebase ID token and admin claim.
- Read-only overview, Meta connection metadata, and recent admin audit events.
- No customer edits, role changes, account suspension, campaign operations, or ad spending.

## Firebase
Uses existing project `adnexa-8daea` and the repository Actions variables: `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`.
Register a separate Android app in Firebase project `adnexa-8daea` with package name `com.adnexa.admin`. Store its Firebase App ID as the GitHub Actions repository variable `ADMIN_FIREBASE_APP_ID`. The shared API key, sender ID, and project ID continue to use the existing repository variables. The admin APK can compile before registration, but Firebase sign-in will remain unavailable until this App ID is configured. Never include service-account credentials in the mobile app or repository.

## Build
Run `flutter pub get`, `flutter analyze`, `flutter test`, `flutter create . --platforms=android --project-name adnexa_admin`, then `flutter build apk --release` from this directory.
