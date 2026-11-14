# Owner-run CONTENTNEX Super Admin bootstrap

This one-time utility adds only the CONTENTNEX-scoped Firebase Custom Claim. It does not deploy a Worker or change ADNEXA's generic `role` claim.

## Target being provisioned

- Firebase project: `adnexa-8daea`
- The owner supplies the target account email and UID through environment variables at runtime; personal account identifiers are not stored in the repository.
- Claim: `contentnexRole=super_admin`

The script still requires the owner to run it in a trusted Google Cloud Shell session. The project, UID, and email are checked before any write. It also requires the account email to be verified and preserves other custom claims.

## Steps in Google Cloud Shell

1. Open [Google Cloud Console](https://console.cloud.google.com/) and select project `adnexa-8daea`.
2. Open Cloud Shell. Sign in with an account that has permission to administer Firebase Authentication custom claims for this project.
3. Confirm the active project:
   ```sh
   gcloud config set project adnexa-8daea
   gcloud auth application-default login
   ```
   Complete Google's sign-in flow inside Cloud Shell. Do not paste credentials or tokens into chat or a repository.
4. Clone the repository and switch to the CONTENTNEX feature branch:
   ```sh
   git clone https://github.com/nattawootbigboy01/adnexa-android.git
   cd adnexa-android
   git checkout feature/contentnex-rebuild-20261115
   ```
5. Install the Admin SDK in a temporary folder (not in the app or Worker bundle):
   ```sh
   mkdir -p /tmp/contentnex-admin-bootstrap
   cd /tmp/contentnex-admin-bootstrap
   npm init -y
   npm install firebase-admin
   ```
6. Copy the repository script into this temporary folder, then run:
   ```sh
   cp ~/adnexa-android/tools/admin-bootstrap/set-contentnex-super-admin.mjs ./set-contentnex-super-admin.mjs
   export GCLOUD_PROJECT=adnexa-8daea
   export CONTENTNEX_ADMIN_UID=8rVDqEe3kjMgXjbjCgGuMEvh5J72
   export CONTENTNEX_ADMIN_EMAIL=nattawootbigboy01@gmail.com
   node set-contentnex-super-admin.mjs
   ```
   If the repository cloned to a different location, adjust only the source path in the `cp` command.
7. After the script reports success, sign out and sign back into CONTENTNEX to refresh the Firebase ID token.

## Important safety notes

- Never download or commit a service-account JSON key. Use Cloud Shell Application Default Credentials.
- Never paste passwords, OTPs, OAuth tokens, access tokens, or credentials into chat.
- Do not change the generic `role` claim. CONTENTNEX uses only `contentnexRole`.
- This script grants a CONTENTNEX claim only. It does not grant an ADNEXA role.
- The Worker source must be deployed separately before the app can verify admin access through `/v1/admin/access-check`. Do not treat a successful claim write as proof that the production Worker is live.
- To revoke CONTENTNEX admin access, use a trusted Admin SDK session to remove only `contentnexRole` from that user's custom claims while preserving all other claims.
