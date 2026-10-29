import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, getDocs, collection, setDoc, writeBatch } from 'firebase/firestore';

const day = '2026-10-29';
let env;

const anon = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();
const apple = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'apple.com' } }).firestore();

/** Seeds data with the rules off. */
async function seed(write) {
  await env.withSecurityRulesDisabled(async (context) => write(context.firestore()));
}

const profile = (code) => ({
  broName: '3.5.4821',
  code,
  look: { fur: 'fur.charcoal' },
  streak: 2,
  total: 120,
  islandLevel: 3,
  friendCount: 0,
  showOnEveryone: true,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-pushup-bro',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (db) => {
    await setDoc(doc(db, 'codes/AAAAAA'), { uid: 'alice' });
    await setDoc(doc(db, 'codes/BBBBBB'), { uid: 'bob' });
    await setDoc(doc(db, 'users/alice'), profile('AAAAAA'));
    await setDoc(doc(db, 'users/bob'), profile('BBBBBB'));
  });
});

after(async () => env.cleanup());

describe('backups', () => {
  it('are closed to an anonymous owner', async () => {
    await assertFails(setDoc(doc(anon('alice'), 'users/alice/backup/state'), { v: 1 }));
    await assertFails(getDoc(doc(anon('alice'), 'users/alice/backup/state')));
  });

  it('open for the owner once Apple or Google is linked', async () => {
    await assertSucceeds(setDoc(doc(apple('alice'), 'users/alice/backup/state'), { v: 1 }));
    await assertSucceeds(getDoc(doc(apple('alice'), 'users/alice/backup/state')));
  });

  it('stay closed to everyone else', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice/backup/state'), { v: 1 }));
    await assertFails(getDoc(doc(apple('bob'), 'users/alice/backup/state')));
    await assertFails(setDoc(doc(apple('bob'), 'users/alice/backup/state'), { v: 2 }));
  });
});

describe('codes', () => {
  it('are claimed once, for yourself', async () => {
    await assertSucceeds(setDoc(doc(anon('carol'), 'codes/CCCCCC'), { uid: 'carol' }));
    await assertFails(setDoc(doc(anon('carol'), 'codes/DDDDDD'), { uid: 'dave' }));
    await assertFails(setDoc(doc(anon('carol'), 'codes/AAAAAA'), { uid: 'carol' }));
  });

  it('only use the friend code alphabet', async () => {
    await assertFails(setDoc(doc(anon('carol'), 'codes/OOOOO0'), { uid: 'carol' }));
  });

  it('can be looked up but not listed', async () => {
    await assertSucceeds(getDoc(doc(anon('carol'), 'codes/AAAAAA')));
    await assertFails(getDocs(collection(anon('carol'), 'codes')));
  });
});

describe('profiles', () => {
  it('need a code the player owns', async () => {
    await assertFails(setDoc(doc(anon('carol'), 'users/carol'), profile('AAAAAA')));
    await seed((db) => setDoc(doc(db, 'codes/CCCCCC'), { uid: 'carol' }));
    await assertSucceeds(setDoc(doc(anon('carol'), 'users/carol'), profile('CCCCCC')));
  });

  it('keep their code and bro name', async () => {
    await assertFails(setDoc(doc(anon('alice'), 'users/alice'), profile('BBBBBB')));
    await assertSucceeds(setDoc(doc(anon('alice'), 'users/alice'), { ...profile('AAAAAA'), streak: 3 }));
  });

  it('are written only by their owner', async () => {
    await assertFails(setDoc(doc(anon('bob'), 'users/alice'), { ...profile('AAAAAA'), streak: 99 }));
  });
});

describe('friends', () => {
  it('can be added with the friend\'s code, both edges', async () => {
    const db = anon('alice');
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/alice/friends/bob'), { code: 'BBBBBB' });
    batch.set(doc(db, 'users/bob/friends/alice'), { code: 'BBBBBB' });
    await assertSucceeds(batch.commit());
  });

  it('can\'t be added without their code', async () => {
    const db = anon('alice');
    await assertFails(setDoc(doc(db, 'users/bob/friends/alice'), { code: 'AAAAAA' }));
    await assertFails(setDoc(doc(db, 'users/alice/friends/bob'), { code: 'AAAAAA' }));
  });

  it('can\'t be made for other players', async () => {
    await assertFails(setDoc(doc(anon('carol'), 'users/alice/friends/bob'), { code: 'BBBBBB' }));
  });

  it('can\'t be added once blocked', async () => {
    await seed((db) => setDoc(doc(db, 'users/bob/blocked/alice'), {}));
    await assertFails(setDoc(doc(anon('alice'), 'users/alice/friends/bob'), { code: 'BBBBBB' }));
  });

  it('can be removed by either side', async () => {
    await seed((db) => setDoc(doc(db, 'users/bob/friends/alice'), { code: 'BBBBBB' }));
    await assertSucceeds(deleteDoc(doc(anon('alice'), 'users/bob/friends/alice')));
  });
});

describe('names for friends', () => {
  beforeEach(async () => {
    await seed((db) => setDoc(doc(db, 'users/alice/private/profile'), { friendName: 'Alice' }));
  });

  it('are read by friends', async () => {
    await seed((db) => setDoc(doc(db, 'users/alice/friends/bob'), { code: 'BBBBBB' }));
    await assertSucceeds(getDoc(doc(anon('bob'), 'users/alice/private/profile')));
  });

  it('are hidden from strangers', async () => {
    await assertFails(getDoc(doc(anon('carol'), 'users/alice/private/profile')));
  });
});

describe('scores', () => {
  const score = (count) => ({ count, broName: '3.5.4821', look: {}, streak: 1, public: true, updatedAt: 1 });

  it('are written by their owner, under their own uid', async () => {
    await assertSucceeds(setDoc(doc(anon('alice'), `days/${day}/scores/alice`), score(40)));
    await assertFails(setDoc(doc(anon('alice'), `days/${day}/scores/bob`), score(40)));
  });

  it('stop at 1500 a day', async () => {
    await assertSucceeds(setDoc(doc(anon('alice'), `days/${day}/scores/alice`), score(1500)));
    await assertFails(setDoc(doc(anon('alice'), `days/${day}/scores/alice`), score(1501)));
  });

  it('only go up within a day', async () => {
    await seed((db) => setDoc(doc(db, `days/${day}/scores/alice`), score(80)));
    await assertFails(setDoc(doc(anon('alice'), `days/${day}/scores/alice`), score(79)));
    await assertSucceeds(setDoc(doc(anon('alice'), `days/${day}/scores/alice`), score(85)));
  });

  it('are read by everyone signed in', async () => {
    await assertSucceeds(getDocs(collection(anon('carol'), `days/${day}/scores`)));
  });
});

describe('inbox', () => {
  const nudge = { kind: 'nudge', fromUid: 'bob', fromName: 'Bob', sentAt: 1 };
  const id = `nudge_bob_${day}`;

  beforeEach(async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'users/alice/friends/bob'), { code: 'BBBBBB' });
      await setDoc(doc(db, 'users/bob/friends/alice'), { code: 'BBBBBB' });
    });
  });

  it('takes one nudge a day from a friend', async () => {
    await assertSucceeds(setDoc(doc(anon('bob'), `users/alice/inbox/${id}`), nudge));
    await assertFails(setDoc(doc(anon('bob'), `users/alice/inbox/${id}`), nudge));
  });

  it('needs the nudge id for the sender and day', async () => {
    await assertFails(setDoc(doc(anon('bob'), 'users/alice/inbox/nudge_carol_2026-10-29'), nudge));
  });

  it('refuses strangers', async () => {
    await assertFails(
      setDoc(doc(anon('carol'), 'users/alice/inbox/wave_carol_1'), { ...nudge, kind: 'wave', fromUid: 'carol' }),
    );
  });

  it('is read only by its owner', async () => {
    await assertFails(getDocs(collection(anon('bob'), 'users/alice/inbox')));
    await assertSucceeds(getDocs(collection(anon('alice'), 'users/alice/inbox')));
  });
});

describe('devices', () => {
  const device = { token: 'tok1', language: 'de', updatedAt: 1 };

  it('are written and read only by their owner', async () => {
    await assertSucceeds(setDoc(doc(anon('alice'), 'users/alice/devices/tok1'), device));
    await assertSucceeds(getDoc(doc(anon('alice'), 'users/alice/devices/tok1')));
    await assertFails(getDoc(doc(anon('bob'), 'users/alice/devices/tok1')));
    await assertFails(setDoc(doc(anon('bob'), 'users/alice/devices/tok2'), { ...device, token: 'tok2' }));
  });

  it('are stored under their own token', async () => {
    await assertFails(setDoc(doc(anon('alice'), 'users/alice/devices/other'), device));
  });

  it('take only the known fields and languages', async () => {
    await assertFails(setDoc(doc(anon('alice'), 'users/alice/devices/tok1'), { ...device, extra: 1 }));
    await assertFails(setDoc(doc(anon('alice'), 'users/alice/devices/tok1'), { ...device, language: 'fr' }));
  });
});
