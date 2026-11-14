# CONTENTNEX Architecture (foundation)

## Current verified state

- Android client: Flutter / Dart.
- Authentication: Firebase Authentication (email/password and email verification).
- Local campaign drafts: SharedPreferences.
- Current AI planning helpers: offline rule-based sample logic in the app.
- No production AI provider, server-side API, user-content database, or admin role
  implementation is present in the current branch yet.

## Target architecture

```
Flutter Android
  UI / feature screens
       |
  Feature services
       |
  AiOrchestrator (provider-neutral)
       |
  Backend API (planned)
       |
  Gemini provider (planned; server-side secret only)
```

## Planned feature boundaries

- `lib/core/ai`: provider-neutral request and orchestration contracts.
- `lib/features/ai_council`: strategy workflow and reviewer roles.
- `lib/features/copywriter`: product copy, hooks, captions and CTA.
- `lib/features/poster_studio`: poster briefs and layout specifications.
- `lib/features/video_script`: scenes, dialogue and timing.
- `lib/features/content_planner`: 7 / 14 / 30-day calendars.
- `lib/features/content_library`: saved drafts and version history.
- `lib/features/admin`: administrative tools and role-gated operations.
- `backend`: planned authenticated API and provider integration.

## Security and cost rules

1. Never place Gemini API keys or other secrets in Dart source, assets, or APK.
2. The Android app must call an authenticated backend for any API-based AI request.
3. Keep API use disabled until a no-billing / free-quota configuration is verified.
4. Do not enable billing, add a payment method, or create paid resources without
   explicit user approval.
5. Show users what content will be sent to an external AI provider.
6. Treat model output as a draft. The user must review and approve it.
7. Keep campaign publishing and ad spend outside prototype testing.
8. Admin and customer permissions must be enforced by the backend, not only UI.

## Implementation sequence

1. Keep Firebase Auth stable and repair the widget test.
2. Add provider-neutral AI contracts (this phase).
3. Add a backend design and authentication boundary.
4. Implement Gemini Hybrid routing only after quota, privacy, and secret handling
   have been reviewed.
5. Add feature modules one at a time with tests.
6. Add persistent user content and server-enforced admin/customer roles.

This document describes the target design; it does not claim that the planned
backend or AI integrations are already deployed.
