# CONTENTNEX Gemini Hybrid Design

Status: **design only**. Gemini API calls and account hand-off are not implemented by this document.

## Intended user experience

CONTENTNEX offers two execution routes behind the same AI task interface:

1. **Automatic route (Gemini API)** — available only after a backend is deployed, a supported free quota is confirmed, and a server-side secret is configured without enabling paid billing.
2. **Manual account route** — CONTENTNEX prepares a task-specific prompt. The user opens their own Gemini account, pastes the prompt, reviews the response, then returns and pastes the result into CONTENTNEX.

A Google AI Pro subscription is not an API entitlement. Consumer Gemini subscription access and Gemini API quota/billing are separate. The app must not imply that a paid consumer subscription makes API calls free.

## Routing rules

- The user can see which route is being used before content leaves the device.
- Automatic route is disabled by default until quota, provider terms, data handling, and secret storage are verified.
- If the API route is disabled, rate-limited, or unavailable, offer manual route without silently transmitting content elsewhere.
- Never switch to an external provider without user-visible notice and consent.
- A manual route must not attempt browser automation, scrape account pages, or request Gemini passwords/cookies.
- Do not ask the user to paste API keys into the app or chat.

## Privacy and consent

Before an automatic request, show the task prompt and relevant context that will be sent to Google. Require explicit consent for external processing. Do not include personal, financial, authentication, or other sensitive data unless essential and explicitly approved.

The user must be able to cancel before submission. Avoid retaining prompts and outputs on the server by default. If retention becomes necessary, specify purpose, access, retention period, and deletion behavior before implementation.

## Provider secret and quota controls

- Gemini API credentials belong only in backend secret storage.
- Never commit credentials to GitHub or include them in Flutter build arguments.
- Do not enable Google Cloud billing, add a payment method, or create paid resources without explicit approval.
- Before enabling API mode, verify current free-tier availability, rate limits, model availability, and data-use terms from official documentation.
- Add per-user and global request limits, maximum prompt size, timeouts, and a kill switch.
- When quota is exhausted, stop API calls and offer manual mode. Never retry in a loop.

## AI Council workflow

The initial implementation may use one approved model with separate role prompts rather than multiple paid model calls:

1. Council planner: identify audience, offer, and content angle.
2. Copywriter: draft hooks, captions, and calls to action.
3. Poster Studio: produce a visual brief and layout specification (not an image unless an image tool is separately integrated).
4. Video Script Studio: draft scenes, dialogue, and timing.
5. Quality Controller: review consistency, clarity, unsupported claims, and policy risks.

Each stage must receive only the context it needs. The final result is a draft and requires user review and approval. The orchestrator must identify each role in the output and must not claim that a separate model was used if the same model handled all roles.

## Rollout gates

Do not activate Gemini API mode until all are true:
- A backend endpoint exists and verifies Firebase ID tokens.
- Secret storage is server-side and tested.
- Free quota and data-use terms are verified.
- User consent and clear route selection are implemented.
- Rate limits, timeout, error handling, and kill switch are tested.
- No billing/payment method is enabled without separate approval.

Until then, only provider-neutral code and manual prompt preparation may be developed.
