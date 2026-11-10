# ADNEXA Android

Premium dark advertising-management mobile prototype built with Flutter.

## Current scope
- Dashboard with sample performance metrics
- Campaign Studio with local draft creation
- Account Center with Meta OAuth client integration (requires Worker deployment and Meta app configuration); TikTok connection remains a placeholder
- Offline sample ad-copy generator
- Analytics demo screen
- GitHub Actions workflow to build a release APK

## Important limitations
This is an early-stage prototype. Metrics are sample data. No real ads are created, published, or billed. Meta OAuth backend and Android client source are present on the Meta integration feature branch but have not been deployed or end-to-end tested. TikTok OAuth, platform API approvals, billing, and live analytics are not implemented.

ADNEXA will never ask users to enter their Meta, TikTok, or Google account passwords into the app. Production integrations must use each platform's official OAuth flow and approved APIs.

## Build APK without a credit card
1. Open the repository's Actions tab.
2. Select Build ADNEXA APK.
3. Press Run workflow on the main branch, or wait for a push build.
4. Open the completed run and download the adnexa-android-apk artifact.

GitHub Actions usage is subject to the account's included minutes and storage quota. No paid service or payment method is configured by this project.

## Local build
Install Flutter, then run flutter pub get, flutter create . --platforms=android --project-name adnexa, and flutter build apk --release.
