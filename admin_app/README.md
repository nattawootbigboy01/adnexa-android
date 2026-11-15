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

Do not put service-account credentials or private API secrets in the app.

## Current limitations

This is an initial UI/authentication scaffold. The separate Firebase project, Android platform runner/package ID, admin account provisioning in that project, API integration, and release build still need to be completed. Do not distribute this scaffold as a production admin app.
