# ADNEXA Android

Flutter Android apps for **ADNEXA ADS — ยิงแอดระดับเทพ**. The feature branch currently under validation is `feature/admin-member-management-20261111`. Keep `main` untouched unless a separate merge approval is given.

## Customer app

- **Dashboard and Insights:** account-level Meta Ads reporting through the ADNEXA Cloudflare Worker. Read-only and dependent on an officially connected account and granted `ads_read` permission.
- **Account Center:** official Meta OAuth connection. Meta access tokens are stored encrypted by the Worker and are not returned to the Android app. TikTok remains a placeholder until its official server-side OAuth exchange is implemented.
- **Campaign Studio:** local planning and draft storage only. The current reach estimate uses planning assumptions of CPM ฿30–฿100 and frequency 1.2–2.0. It is not a Meta forecast or guarantee. Measured platform results are shown separately. No campaign create, edit, pause, publish, or spend endpoint is implemented.
- **Planner:** offline rule-based helper, not a hosted AI service.
- **Customer-app Admin Control Center:** read-only overview, Meta connection metadata, and audit information for users whose trusted Firebase claim is recognized by the Worker.

## Separate ADNEXA ADMIN app

The `admin_app/` directory contains a separate Flutter app for administrators.

- Email/password sign-in only; there is no public registration screen.
- Access requires a verified Firebase email and a server-approved role in the D1 `admin_roles` registry.
- The member directory is populated after a customer verifies their email and signs in with a build that includes the profile-sync call; existing users are not bulk-imported.
- Super administrators can grant or revoke `admin` and `support` roles. The server blocks self-role changes and changes to the `super_admin` account.
- Member and role endpoints independently verify the Firebase ID token and role on the server.
- Account suspension/deletion, campaign operations, and ad spending are not included.

## Security and operational boundaries

- Firebase ID tokens are verified by the Worker; administrator endpoints also require a verified email and a current D1 role.
- Meta tokens use AES-256-GCM encryption at rest with a fresh IV for each encryption.
- Firebase build configuration is passed through GitHub Actions variables. Keep Meta app secrets and the token-encryption key only in Cloudflare Worker secrets.
- Never commit credentials, access tokens, encryption keys, or passwords.
- The APK workflow does not deploy the Worker, connect customer accounts, publish an app, create campaigns, or spend ad budget. Worker deployment and any live platform testing require separate approval.

## CI build and test

The `Build ADNEXA APK` workflow runs on pushes to `feature/admin-member-management-20261111` and can also be started manually with `workflow_dispatch`. It has two jobs:

1. Customer app: Worker JavaScript syntax check, Flutter dependency installation, `flutter analyze`, `flutter test`, and release APK build.
2. Admin app: Flutter dependency installation, `flutter analyze`, `flutter test`, and separate release APK build.

Successful runs upload `adnexa-android-apk` and `adnexa-admin-apk`. An uploaded release artifact is not, by itself, proof that its signing certificate is suitable for installation or production distribution; verify the APK signature before distributing it. The workflow does not run automatically for pull requests.

For the admin APK, register the separate Firebase Android app with package name `com.adnexa.admin` and set its Firebase App ID as the GitHub Actions variable `ADMIN_FIREBASE_APP_ID`. The shared Firebase API key, sender ID, and project ID use the existing repository variables.

## Local build

From the repository root:

```sh
flutter pub get
flutter analyze
flutter test
flutter create . --platforms=android --project-name adnexa
flutter build apk --release
```

For the separate admin app, run the equivalent Flutter commands from `admin_app/` using `--org com.adnexa --project-name admin` when generating Android project files.
