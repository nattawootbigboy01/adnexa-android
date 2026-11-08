# ADNEXA Android

Premium dark advertising-management mobile prototype built with Flutter.

## Current scope
- Dashboard with sample performance metrics
- Campaign Studio with local draft creation
- Account Center placeholders for Meta, TikTok and Google
- Offline sample ad-copy generator
- Analytics demo screen
- Billing prototype with bank transfer, PromptPay, card, and monthly auto-renewal preferences
- GitHub Actions workflow to build a release APK

## Important limitations
This is a UI prototype. Metrics are sample data. No real ads are created, published, or billed. Platform connection buttons are placeholders. Real OAuth, server-side token storage, platform API approvals, backend authentication, payment gateway integration, recurring card billing, QR generation, bank-transfer verification, and live analytics are not implemented. Billing options are UI-only and do not collect or charge money.

ADNEXA will never ask users to enter their Meta, TikTok, or Google account passwords into the app. Production integrations must use each platform's official OAuth flow and approved APIs.

## Build APK without a credit card
1. Open the repository's Actions tab.
2. Select Build ADNEXA APK.
3. Press Run workflow on the main branch, or wait for a push build.
4. Open the completed run and download the adnexa-android-apk artifact.

GitHub Actions usage is subject to the account's included minutes and storage quota. No paid service or payment method is configured by this project.

## Local build
Install Flutter, then run flutter pub get, flutter create . --platforms=android --project-name adnexa, and flutter build apk --release.
