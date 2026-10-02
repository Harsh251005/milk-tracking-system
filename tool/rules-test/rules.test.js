// Firestore security rules tests. Run from this folder with `npm test`
// (starts the local Firestore emulator; no cloud project or cost involved).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteField,
  doc,
  getDoc,
  getDocs,
  collection,
  setDoc,
  Timestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const HOUSE = 'house1';
const CODE = '482913';
const hours = (h) => Timestamp.fromMillis(Date.now() + h * 3600 * 1000);

let env;
const db = (uid) => env.authenticatedContext(uid).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-milk-tracker',
    firestore: { rules: readFileSync('../../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

// Mom owns house1; a live invite exists; Dad and a stranger are not members.
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    await setDoc(doc(f, 'households', HOUSE), {
      name: 'Home',
      members: { mom: 'Mom' },
      products: { p1: { name: 'Cow milk', ratePaise: 7000, usualMl: 1000 } },
      milkman: {},
      createdBy: 'mom',
    });
    await setDoc(doc(f, 'households', HOUSE, 'entries', '2026-10-02'), {
      date: '2026-10-02',
      status: 'got',
    });
    await setDoc(doc(f, 'joinCodes', CODE), {
      householdId: HOUSE,
      invitedBy: 'Mom',
      createdBy: 'mom',
      expiresAt: hours(24),
    });
  });
});

const join = (uid, { code = CODE, name = 'Dad', extra = {} } = {}) => {
  const f = db(uid);
  const batch = writeBatch(f);
  batch.update(doc(f, 'households', HOUSE), {
    [`members.${uid}`]: name,
    lastJoinCode: code,
    ...extra,
  });
  batch.set(doc(f, 'users', uid), { householdId: HOUSE });
  return batch.commit();
};

describe('households', () => {
  test('members read; strangers cannot', async () => {
    await assertSucceeds(getDoc(doc(db('mom'), 'households', HOUSE)));
    await assertFails(getDoc(doc(db('stranger'), 'households', HOUSE)));
    await assertFails(getDocs(collection(db('stranger'), 'households')));
  });

  test('strangers cannot read or write entries', async () => {
    const f = db('stranger');
    await assertFails(getDoc(doc(f, 'households', HOUSE, 'entries', '2026-10-02')));
    await assertFails(
      setDoc(doc(f, 'households', HOUSE, 'entries', '2026-10-03'), { date: 'x' }),
    );
  });

  test('anyone can create a household with only themselves in it', async () => {
    const f = db('aunt');
    await assertSucceeds(
      setDoc(doc(f, 'households', 'house2'), {
        members: { aunt: 'Aunt' },
        createdBy: 'aunt',
      }),
    );
    await assertFails(
      setDoc(doc(f, 'households', 'house3'), {
        members: { aunt: 'Aunt', mom: 'Mom' },
        createdBy: 'aunt',
      }),
    );
  });

  test('a member cannot add someone else directly', async () => {
    await assertFails(
      updateDoc(doc(db('mom'), 'households', HOUSE), { 'members.dad': 'Dad' }),
    );
  });

  test('a member can unlink another phone', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'households', HOUSE), { 'members.old': 'Old' }),
    );
    await assertSucceeds(
      updateDoc(doc(db('mom'), 'households', HOUSE), { 'members.old': deleteField() }),
    );
    await assertFails(getDoc(doc(db('old'), 'households', HOUSE)));
  });

  test('a member can edit settings and their own name', async () => {
    await assertSucceeds(
      updateDoc(doc(db('mom'), 'households', HOUSE), {
        'products.p1.ratePaise': 7200,
        'members.mom': 'Mummy',
      }),
    );
  });
});

describe('joining with a code', () => {
  test('a live code lets a phone add itself, then read and log', async () => {
    await assertSucceeds(join('dad'));
    const f = db('dad');
    await assertSucceeds(getDoc(doc(f, 'households', HOUSE)));
    await assertSucceeds(
      setDoc(doc(f, 'households', HOUSE, 'entries', '2026-10-03'), { date: 'x' }),
    );
  });

  test('a wrong code is rejected', async () => {
    await assertFails(join('dad', { code: '000000' }));
  });

  test('an expired code is rejected', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'joinCodes', CODE), { expiresAt: hours(-1) }),
    );
    await assertFails(join('dad'));
  });

  test('a code for another household is rejected', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'joinCodes', CODE), { householdId: 'other' }),
    );
    await assertFails(join('dad'));
  });

  test('joining cannot add a second person or change settings', async () => {
    await assertFails(join('dad', { extra: { 'members.friend': 'Friend' } }));
    await assertFails(join('dad', { extra: { 'products.p1.ratePaise': 1 } }));
  });

  test('joining cannot remove existing members', async () => {
    await assertFails(join('dad', { extra: { 'members.mom': deleteField() } }));
  });
});

describe('joinCodes', () => {
  test('fetch by exact code only, never list', async () => {
    await assertSucceeds(getDoc(doc(db('dad'), 'joinCodes', CODE)));
    await assertFails(getDocs(collection(db('dad'), 'joinCodes')));
  });

  test('only members create codes, for their own household', async () => {
    const code = (f, id, data) => setDoc(doc(f, 'joinCodes', id), data);
    const valid = { householdId: HOUSE, createdBy: 'mom', expiresAt: hours(24) };
    await assertSucceeds(code(db('mom'), '111111', valid));
    await assertFails(
      code(db('stranger'), '222222', { ...valid, createdBy: 'stranger' }),
    );
  });

  test('codes cannot be overwritten, run for days, or be non-numeric', async () => {
    const valid = { householdId: HOUSE, createdBy: 'mom', expiresAt: hours(24) };
    await assertFails(setDoc(doc(db('mom'), 'joinCodes', CODE), valid));
    await assertFails(
      setDoc(doc(db('mom'), 'joinCodes', '333333'), { ...valid, expiresAt: hours(72) }),
    );
    await assertFails(setDoc(doc(db('mom'), 'joinCodes', 'abcdef'), valid));
  });
});

describe('users', () => {
  test('each phone touches only its own pointer', async () => {
    await assertSucceeds(setDoc(doc(db('dad'), 'users', 'dad'), { householdId: 'x' }));
    await assertFails(getDoc(doc(db('dad'), 'users', 'mom')));
    await assertFails(setDoc(doc(db('dad'), 'users', 'mom'), { householdId: 'x' }));
  });
});
