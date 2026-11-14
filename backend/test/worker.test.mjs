import test from 'node:test';
import assert from 'node:assert/strict';
import worker, { validateAiRequest } from '../src/index.mjs';

const env = { FIREBASE_PROJECT_ID: 'adnexa-8daea' };

test('health endpoint reports service status without enabling AI', async () => {
  const response = await worker.fetch(
    new Request('https://contentnex-api.test/v1/health'),
    env,
  );
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.service, 'contentnex-api');
  assert.equal(body.aiProviderEnabled, false);
});

test('AI endpoint rejects requests without a Firebase bearer token', async () => {
  const response = await worker.fetch(
    new Request('https://contentnex-api.test/v1/ai/generate', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        task: 'copywriter',
        prompt: 'เขียนแคปชัน',
        consent: { externalAiProcessing: true },
      }),
    }),
    env,
  );
  const body = await response.json();

  assert.equal(response.status, 401);
  assert.equal(body.error.code, 'UNAUTHENTICATED');
});

test('valid AI request shape passes validation without calling a provider', () => {
  assert.equal(validateAiRequest({
    task: 'copywriter',
    prompt: 'เขียนแคปชันสินค้า',
    languageCode: 'th',
    context: { productCategory: 'food' },
    consent: { externalAiProcessing: true },
  }), null);
});

test('unknown top-level request fields are rejected', () => {
  assert.equal(validateAiRequest({
    task: 'copywriter',
    prompt: 'เขียนแคปชัน',
    consent: { externalAiProcessing: true },
    userId: 'attacker-controlled',
  }), 'UNKNOWN_REQUEST_FIELD');
});

test('external AI consent must be explicit and have the expected shape', () => {
  const base = { task: 'copywriter', prompt: 'เขียนแคปชัน' };
  assert.equal(validateAiRequest({ ...base, consent: {} }), 'EXTERNAL_AI_CONSENT_REQUIRED');
  assert.equal(validateAiRequest({
    ...base,
    consent: { externalAiProcessing: true, bypassPrivacy: true },
  }), 'EXTERNAL_AI_CONSENT_REQUIRED');
});

test('context must be a bounded string map', () => {
  assert.equal(validateAiRequest({
    task: 'copywriter',
    prompt: 'เขียนแคปชัน',
    context: { product: { nested: true } },
    consent: { externalAiProcessing: true },
  }), 'INVALID_CONTEXT');
});

test('unknown routes return a JSON 404', async () => {
  const response = await worker.fetch(
    new Request('https://contentnex-api.test/not-a-route'),
    env,
  );
  assert.equal(response.status, 404);
});
