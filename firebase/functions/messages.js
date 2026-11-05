// What a bro's push notification says, in the language their app is set
// to. The same words as the inbox banner in the app (assets/l10n).

const texts = {
  en: {
    wave: (name) => `${name} waved at you 👋`,
    banana: (name) => `${name} sent you a banana 🍌`,
    nudge: (name) => `${name} nudged you: time for pushups! 💪`,
    drop: (name) => `${name} dropped a gift on your island 🎁`,
  },
  de: {
    wave: (name) => `${name} hat dir gewunken 👋`,
    banana: (name) => `${name} hat dir eine Banane geschickt 🍌`,
    nudge: (name) => `${name} stupst dich an: Zeit für Liegestütze! 💪`,
    drop: (name) => `${name} hat ein Geschenk auf deiner Insel abgeworfen 🎁`,
  },
  es: {
    wave: (name) => `${name} te saludó 👋`,
    banana: (name) => `${name} te envió un plátano 🍌`,
    nudge: (name) => `${name} te avisa: ¡hora de flexiones! 💪`,
    drop: (name) => `${name} dejó caer un regalo en tu isla 🎁`,
  },
  ja: {
    wave: (name) => `${name}が手を振った 👋`,
    banana: (name) => `${name}がバナナをくれた 🍌`,
    nudge: (name) => `${name}がつついた：腕立て伏せの時間だ！💪`,
    drop: (name) => `${name}があなたの島にプレゼントを落とした 🎁`,
  },
  pt: {
    wave: (name) => `${name} acenou para você 👋`,
    banana: (name) => `${name} te mandou uma banana 🍌`,
    nudge: (name) => `${name} te cutucou: hora das flexões! 💪`,
    drop: (name) => `${name} deixou um presente na sua ilha 🎁`,
  },
};

/** Where a tap on the notification takes the player. */
export const route = '/island/bros';

/** A gift dropped from the airport waits on the island itself. */
export const dropRoute = '/island';

/** The text for an inbox [item] in [language], or null for an unknown kind. */
export function textFor(item, language) {
  const words = texts[language] ?? texts.en;
  const say = words[item.kind];
  if (!say) return null;
  const name = String(item.fromName ?? '').trim().slice(0, 24) || 'Bro';
  return say(name);
}

/**
 * The FCM message for [item] on one iPhone. Nudges from the same bro
 * replace each other; everything lands in one "Bros" thread.
 */
export function messageFor(item, device) {
  const body = textFor(item, device.language);
  if (!body) return null;
  return {
    token: device.token,
    notification: { body },
    data: { route: item.kind === 'drop' ? dropRoute : route, kind: item.kind, fromUid: String(item.fromUid ?? '') },
    apns: {
      headers: {
        'apns-push-type': 'alert',
        ...(item.kind === 'nudge' ? { 'apns-collapse-id': `nudge_${item.fromUid}` } : {}),
      },
      payload: { aps: { sound: 'default', 'thread-id': 'bros' } },
    },
  };
}

/** FCM errors that mean the token is gone for good. */
export const staleTokenErrors = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);
