import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const EXPECTED_PROJECT_ID = 'adnexa-8daea';
const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
const uid = process.env.CONTENTNEX_ADMIN_UID;
const expectedEmail = process.env.CONTENTNEX_ADMIN_EMAIL?.trim().toLowerCase();

if (projectId !== EXPECTED_PROJECT_ID) {
  throw new Error(`Refusing to run: expected project ${EXPECTED_PROJECT_ID}; received ${projectId || '(unset)'}.`);
}
if (!uid || !expectedEmail) {
  throw new Error('Set CONTENTNEX_ADMIN_UID and CONTENTNEX_ADMIN_EMAIL before running.');
}

initializeApp({
  credential: applicationDefault(),
  projectId: EXPECTED_PROJECT_ID,
});

const auth = getAuth();
const user = await auth.getUser(uid);

if ((user.email || '').toLowerCase() !== expectedEmail) {
  throw new Error('UID/email mismatch. No claims were changed.');
}
if (user.emailVerified !== true) {
  throw new Error('The target Firebase account email is not verified. No claims were changed.');
}

const existingClaims = user.customClaims || {};
if (
  existingClaims.contentnexRole &&
  existingClaims.contentnexRole !== 'customer' &&
  existingClaims.contentnexRole !== 'super_admin'
) {
  throw new Error('An unexpected contentnexRole already exists. Manual review required; no claims were changed.');
}

await auth.setCustomUserClaims(uid, {
  ...existingClaims,
  contentnexRole: 'super_admin',
});

const updated = await auth.getUser(uid);
if (updated.customClaims?.contentnexRole !== 'super_admin') {
  throw new Error('Claim write could not be verified.');
}

console.log('CONTENTNEX Super Admin claim assigned and verified.');
console.log(`Project: ${EXPECTED_PROJECT_ID}`);
console.log(`UID: ${uid}`);
console.log('Claim: contentnexRole=super_admin');
console.log('Other existing custom claims were preserved.');
console.log('Sign out and sign in again in the app to refresh the Firebase ID token.');
