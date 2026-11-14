# CONTENTNEX Android

AI-powered content business studio for online sellers, built with Flutter.

## Current scope
- Dashboard สำหรับภาพรวมการทำคอนเทนต์
- Content Studio with local draft creation
- ศูนย์เชื่อมต่อแพลตฟอร์ม placeholders for Meta, TikTok and Google
- เครื่องมือช่วยร่างข้อความคอนเทนต์แบบออฟไลน์ (เทมเพลต)
- ผลลัพธ์คอนเทนต์ demo screen
- GitHub Actions workflow to build a release APK

## Important limitations
This is a UI prototype. Metrics are sample data. No real ads are created, published, or billed. Platform connection buttons are placeholders. Real OAuth, server-side token storage, platform API approvals, backend authentication, billing, and live analytics are not implemented.

CONTENTNEX will never ask users to enter their Meta, TikTok, or Google account passwords into the app. Production integrations must use each platform's official OAuth flow and approved APIs.

## Build APK without a credit card
1. Open the repository's Actions tab.
2. Select Build CONTENTNEX APK.
3. Press Run workflow on the main branch, or wait for a push build.
4. Open the completed run and download the contentnex-android-apk artifact.

GitHub Actions usage is subject to the account's included minutes and storage quota. No paid service or payment method is configured by this project.

## Local build
Install Flutter, then run flutter pub get, flutter create . --platforms=android --project-name contentnex, and flutter build apk --release.
