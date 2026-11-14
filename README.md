# CONTENTNEX

AI Content Business Studio — วางแผนและสร้างคอนเทนต์สำหรับธุรกิจในที่เดียว

## Current scope
- Flutter Android application shell and Firebase email/password authentication.
- Dashboard and campaign/account screens that are still prototype UI.
- Provider-neutral AI request, provider, and orchestration contracts.
- Manual Gemini prompt preparation for six approved roles: AI COUNCIL, COPYWRITER, POSTER STUDIO, VIDEO SCRIPT, CONTENT PLANNER, and QUALITY CONTROLLER.
- Manual prompt flow is available in the AI screen; users review and copy the prompt, then open their own Gemini account themselves.
- Cloudflare Worker backend source scaffold (not deployed), Firebase ID-token verification, and Gemini Hybrid design specifications.
- Backend unit tests and a Flutter analyze/test workflow.

## Verified limitations
- Backend Worker source exists but no backend API is deployed or runtime-tested.
- No Gemini API provider is connected; manual mode prepares prompts only and does not contact Gemini.
- The manual Gemini response is not automatically imported back into CONTENTNEX yet.
- Dashboard metrics and platform connection states are sample/demo UI.
- No production admin role enforcement, content database, OAuth token storage, or live analytics.
- No real campaign is created, published, or billed.
- Flutter CI checks are separate from APK builds; no APK build is started by the test workflow.

## Security and cost
- Never put API keys or credentials in Flutter source, assets, or APKs.
- Gemini API mode must remain disabled until backend authentication, free quota, data handling, rate limits, and server-side secret storage are verified.
- A Google AI Pro consumer subscription does not automatically include Gemini API quota.
- Do not enable billing or add a payment method without explicit user approval.
- AI-generated content must remain a draft until the user reviews and approves it.

## Build
The release workflow is manually dispatched from GitHub Actions. Select the approved feature branch:
`feature/contentnex-rebuild-20261115`.

Do not run a build or deploy without explicit approval. GitHub Actions usage may be subject to account quotas.
