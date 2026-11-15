# CONTENTNEX ADMIN app

This is a separate Flutter application for authorized administrators. It is intentionally not part of the customer app's navigation or APK.

## Security model

- Login only. There is no public sign-up flow.
- Email verification is required.
- The dashboard checks the server-issued `contentnexRole=super_admin` custom claim.
- The Worker admin endpoints must validate tokens against a dedicated Firebase project configured as `ADMIN_FIREBASE_PROJECT_ID`.
- The backend must enforce authorization on every admin API request. Hiding a screen in the app is not a security boundary.

## Firebase configuration

Use a dedicated Firebase project for the administrator app. Supply these build-time values when building:

- `ADMIN_FIREBASE_API_KEY`
- `ADMIN_FIREBASE_APP_ID`
- `ADMIN_FIREBASE_MESSAGING_SENDER_ID`
- `ADMIN_FIREBASE_PROJECT_ID`
- `ADMIN_API_BASE_URL` (HTTPS base URL of the deployed CONTENTNEX Worker)

Do not put service-account credentials or private API secrets in the app.

## Current limitations

This is an initial UI/authentication scaffold. The app now requires a successful `GET /v1/admin/access-check` response from the Worker after checking the Firebase custom claim. The separate Firebase project, Android platform runner/package ID, admin account provisioning in that project, Worker environment configuration, and release build still need to be completed. The dashboard is not production-ready and must not be distributed until those steps and tests are complete.
