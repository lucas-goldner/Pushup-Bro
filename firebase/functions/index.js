import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { messageFor, staleTokenErrors } from './messages.js';

initializeApp();

/** Items older than this aren't pushed (a retry long after the fact). */
const maxAgeMs = 10 * 60 * 1000;

/**
 * A wave, banana or nudge landed in a bro's inbox: tell their iPhones.
 * The rules already made sure it came from a friend who isn't blocked.
 */
export const pushInboxItem = onDocumentCreated(
  { document: 'users/{uid}/inbox/{itemId}', region: 'us-central1', retry: false },
  async (event) => {
    const item = event.data?.data();
    if (!item) return;
    if (Date.now() - Date.parse(event.time) > maxAgeMs) return;

    const db = getFirestore();
    const devices = await db.collection(`users/${event.params.uid}/devices`).get();
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
      else logger.warn('Push failed', { code, uid: event.params.uid });
    });
    await Promise.all(stale.map((ref) => ref.delete()));
  },
);
