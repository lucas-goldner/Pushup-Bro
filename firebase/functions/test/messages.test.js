import assert from 'node:assert/strict';
import { test } from 'node:test';
import { messageFor, route, textFor } from '../messages.js';

const wave = { kind: 'wave', fromUid: 'bob', fromName: 'Bob', sentAt: 1 };

test('says it in the device language', () => {
  assert.equal(textFor(wave, 'de'), 'Bob hat dir gewunken 👋');
  assert.equal(textFor({ ...wave, kind: 'banana' }, 'ja'), 'Bobがバナナをくれた 🍌');
});

test('falls back to English for an unknown language', () => {
  assert.equal(textFor(wave, 'fr'), 'Bob waved at you 👋');
});

test('skips unknown kinds', () => {
  assert.equal(textFor({ ...wave, kind: 'party' }, 'en'), null);
  assert.equal(messageFor({ ...wave, kind: 'party' }, { token: 't', language: 'en' }), null);
});

test('names a bro without a name "Bro"', () => {
  assert.equal(textFor({ ...wave, fromName: '  ' }, 'en'), 'Bro waved at you 👋');
});

test('opens the bros and collapses nudges per bro', () => {
  const nudge = messageFor({ ...wave, kind: 'nudge' }, { token: 'tok', language: 'en' });
  assert.equal(nudge.token, 'tok');
  assert.equal(nudge.data.route, route);
  assert.equal(nudge.apns.headers['apns-collapse-id'], 'nudge_bob');
  assert.equal(nudge.apns.payload.aps['thread-id'], 'bros');
  const plain = messageFor(wave, { token: 'tok', language: 'en' });
  assert.equal(plain.apns.headers['apns-collapse-id'], undefined);
});
