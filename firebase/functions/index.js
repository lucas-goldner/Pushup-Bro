import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { messageFor, staleTokenErrors } from './messages.js';

initializeApp();

/** Items older than this aren't pushed (a retry long after the fact). */
const maxAgeMs = 10 * 60 * 1000;

/** Sends [item] to every iPhone of [uid], dropping tokens that are gone. */
async function pushTo(uid, item, time) {
  if (Date.now() - Date.parse(time) > maxAgeMs) return;

  const db = getFirestore();
  const devices = await db.collection(`users/${uid}/devices`).get();
  const sends = devices.docs
    .map((doc) => ({ ref: doc.ref, message: messageFor(item, doc.data()) }))
    .filter((send) => send.message);
  if (sends.length === 0) return;

  const result = await getMessaging().sendEach(sends.map((send) => send.message));
  const stale = [];
  result.responses.forEach((response, i) => {
    if (response.success) return;
    const code = response.error?.code;
    if (staleTokenErrors.has(code)) stale.push(sends[i].ref);
    else logger.warn('Push failed', { code, uid });
  });
  await Promise.all(stale.map((ref) => ref.delete()));
}

/**
 * A wave, banana or nudge landed in a bro's inbox: tell their iPhones.
 * The rules already made sure it came from a friend who isn't blocked.
 */
export const pushInboxItem = onDocumentCreated(
  { document: 'users/{uid}/inbox/{itemId}', region: 'us-central1', retry: false },
  async (event) => {
    const item = event.data?.data();
    if (!item) return;
    await pushTo(event.params.uid, item, event.time);
  },
);

/** A friend dropped a gift on a bro's island from the airport. */
export const pushGiftDrop = onDocumentCreated(
  { document: 'users/{uid}/drops/{dropId}', region: 'us-central1', retry: false },
  async (event) => {
    const drop = event.data?.data();
    if (!drop) return;
    await pushTo(event.params.uid, { ...drop, kind: 'drop' }, event.time);
  },
);
