import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  writeBatch,
} from 'firebase/firestore';

const rulesDir = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

function emulatorHost(envVar) {
  const value = process.env[envVar];
  assert.ok(value, `${envVar} must be set (run via firebase emulators:exec)`);
  const [host, port] = value.split(':');
  return { host, port: Number(port) };
}

const PROJECT_ID = 'demo-everything-passport';
const ADMIN_EMAIL = 'admin@example.com';
const USER_EMAIL = 'user@example.com';

const VALID_PROFILE = {
  email: USER_EMAIL,
  username: 'alice',
  firstName: 'Alice',
  lastName: 'Anderson',
  isPublic: false,
  dateOfBirth: null,
  nationality: null,
  photoUrl: null,
};

let testEnv;

function db(uid, token = {}) {
  return testEnv.authenticatedContext(uid, token).firestore();
}

const adminDb = () =>
  db('admin-uid', { email: ADMIN_EMAIL, email_verified: true });
const userDb = (uid = 'user-1') =>
  db(uid, { email: USER_EMAIL, email_verified: true });
const unverifiedAdminDb = () =>
  db('unverified-uid', { email: ADMIN_EMAIL, email_verified: false });

test.before(async () => {
  const { host, port } = emulatorHost('FIRESTORE_EMULATOR_HOST');
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(join(rulesDir, 'firestore.rules'), 'utf8'),
      host,
      port,
    },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const fs = context.firestore();
    await setDoc(doc(fs, 'admins', ADMIN_EMAIL), { role: 'owner' });
    await setDoc(doc(fs, 'metadata', 'countries'), { options: [] });
    await setDoc(doc(fs, 'userProfiles', 'user-1'), {
      ...VALID_PROFILE,
      username: 'alice',
    });
    await setDoc(doc(fs, 'usernames', 'alice'), { userId: 'user-1' });
    await setDoc(doc(fs, 'userProfiles', 'user-2'), {
      ...VALID_PROFILE,
      email: 'other@example.com',
      username: 'bob',
    });
    await setDoc(doc(fs, 'usernames', 'bob'), { userId: 'user-2' });
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

// --- usernames ---

test('usernames: signed-in users can get a mapping but not list', async () => {
  await assertSucceeds(getDoc(doc(userDb(), 'usernames', 'alice')));
  await assertSucceeds(getDoc(doc(userDb('user-2'), 'usernames', 'alice')));
  await assertFails(
    getDocs(collection(testEnv.unauthenticatedContext().firestore(), 'usernames')),
  );
  await assertFails(getDocs(collection(userDb(), 'usernames')));
  await assertSucceeds(getDocs(collection(adminDb(), 'usernames')));
});

test('usernames: create requires a matching profile write in the same transaction', async () => {
  // Squatting attempt: create a mapping without touching the profile.
  await assertFails(
    setDoc(doc(userDb('user-2'), 'usernames', 'carol'), { userId: 'user-2' }),
  );

  // Legitimate flow: create mapping + update profile username atomically.
  const fs = userDb('user-2');
  const batch = writeBatch(fs);
  batch.set(doc(fs, 'usernames', 'carol'), { userId: 'user-2' });
  batch.set(
    doc(fs, 'userProfiles', 'user-2'),
    { ...VALID_PROFILE, email: 'other@example.com', username: 'carol' },
    { merge: true },
  );
  await assertSucceeds(batch.commit());
});

test('usernames: cannot overwrite an existing mapping or claim another uid', async () => {
  await assertFails(
    setDoc(doc(userDb(), 'usernames', 'alice'), { userId: 'user-1' }),
  );
  await assertFails(
    setDoc(doc(userDb('user-2'), 'usernames', 'dave'), { userId: 'user-1' }),
  );
});

test('usernames: users can delete only their own mapping; admins can delete any', async () => {
  await assertSucceeds(deleteDoc(doc(userDb('user-2'), 'usernames', 'carol')));
  await assertFails(deleteDoc(doc(userDb(), 'usernames', 'bob')));
  await assertSucceeds(deleteDoc(doc(adminDb(), 'usernames', 'bob')));
});

// --- userProfiles ---

test('userProfiles: read is owner-or-admin only', async () => {
  await assertSucceeds(getDoc(doc(userDb(), 'userProfiles', 'user-1')));
  await assertFails(getDoc(doc(userDb('user-2'), 'userProfiles', 'user-1')));
  await assertSucceeds(getDoc(doc(adminDb(), 'userProfiles', 'user-1')));
});

test('userProfiles: writes must pass validation and keep a username mapping', async () => {
  const fs = userDb('user-3');
  const profile = { ...VALID_PROFILE, username: 'erin' };

  // Missing username mapping -> denied.
  await assertFails(setDoc(doc(fs, 'userProfiles', 'user-3'), profile));

  // Full transactional flow -> allowed.
  const batch = writeBatch(fs);
  batch.set(doc(fs, 'usernames', 'erin'), { userId: 'user-3' });
  batch.set(doc(fs, 'userProfiles', 'user-3'), profile);
  await assertSucceeds(batch.commit());
});

test('userProfiles: invalid profile data is rejected for regular users', async () => {
  const fs = userDb('user-4');
  const batch = writeBatch(fs);
  batch.set(doc(fs, 'usernames', 'frank'), { userId: 'user-4' });
  batch.set(doc(fs, 'userProfiles', 'user-4'), {
    ...VALID_PROFILE,
    username: 'frank',
    firstName: '',
  });
  await assertFails(batch.commit());
});

test('userProfiles: admins bypass field validation', async () => {
  await assertSucceeds(
    setDoc(doc(adminDb(), 'userProfiles', 'user-2'), { repaired: true }),
  );
});

// --- metadata ---

test('metadata: readable by signed-in users, writable by admins only', async () => {
  await assertFails(
    getDoc(doc(testEnv.unauthenticatedContext().firestore(), 'metadata', 'countries')),
  );
  await assertSucceeds(getDoc(doc(userDb(), 'metadata', 'countries')));
  await assertFails(setDoc(doc(userDb(), 'metadata', 'countries'), { options: [] }));
  await assertSucceeds(setDoc(doc(adminDb(), 'metadata', 'countries'), { options: [] }));
});

// --- admins ---

test('admins: only admins can write; verified email required', async () => {
  await assertFails(
    setDoc(doc(userDb(), 'admins', 'attacker@example.com'), {}),
  );
  await assertFails(
    setDoc(doc(unverifiedAdminDb(), 'admins', 'x@example.com'), {}),
  );
  await assertSucceeds(
    setDoc(doc(adminDb(), 'admins', 'new-admin@example.com'), {}),
  );
});

// --- secure default ---

test('unscoped collections are admin-only', async () => {
  await assertFails(getDoc(doc(userDb(), 'unknownCollection', 'doc-1')));
  await assertSucceeds(getDoc(doc(adminDb(), 'unknownCollection', 'doc-1')));
});
