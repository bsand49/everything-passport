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
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';

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

const PNG_BYTES = new Uint8Array([0x89, 0x50, 0x4e, 0x47]);

function imageBlob(type = 'image/png') {
  return new Blob([PNG_BYTES], { type });
}

let testEnv;

function storage(uid, token = {}) {
  return testEnv.authenticatedContext(uid, token).storage();
}

const adminStorage = () =>
  storage('admin-uid', { email: ADMIN_EMAIL, email_verified: true });
const userStorage = (uid = 'user-1') =>
  storage(uid, { email: USER_EMAIL, email_verified: true });
const unverifiedAdminStorage = () =>
  storage('unverified-uid', { email: ADMIN_EMAIL, email_verified: false });

test.before(async () => {
  const { host, port } = emulatorHost('FIREBASE_STORAGE_EMULATOR_HOST');
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    storage: {
      rules: readFileSync(join(rulesDir, 'storage.rules'), 'utf8'),
      host,
      port,
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test('profile_pictures: owner can upload, read, and delete images', async () => {
  const path = 'profile_pictures/user-1';
  const fileRef = ref(userStorage(), path);

  await assertSucceeds(uploadBytes(fileRef, imageBlob()));
  await assertSucceeds(getBytes(fileRef));
  await assertSucceeds(deleteObject(fileRef));
});

test('profile_pictures: rejects non-image and oversized uploads', async () => {
  await assertFails(
    uploadBytes(ref(userStorage(), 'profile_pictures/user-1'), imageBlob('text/plain')),
  );
  const big = new Blob([new Uint8Array(5 * 1024 * 1024 + 1)], { type: 'image/png' });
  await assertFails(uploadBytes(ref(userStorage(), 'profile_pictures/user-1'), big));
});

test('profile_pictures: other users cannot read or write', async () => {
  await assertSucceeds(
    uploadBytes(ref(userStorage('user-1'), 'profile_pictures/user-1'), imageBlob()),
  );
  await assertFails(getBytes(ref(userStorage('user-2'), 'profile_pictures/user-1')));
  await assertFails(
    uploadBytes(ref(userStorage('user-2'), 'profile_pictures/user-1'), imageBlob()),
  );
  await assertFails(deleteObject(ref(userStorage('user-2'), 'profile_pictures/user-1')));
});

test('profile_pictures: unauthenticated access is denied', async () => {
  const unauth = testEnv.unauthenticatedContext().storage();
  await assertFails(getBytes(ref(unauth, 'profile_pictures/user-1')));
});

test('profile_pictures: admins can access any path with verified email', async () => {
  const fileRef = ref(adminStorage(), 'profile_pictures/user-9');
  await assertSucceeds(uploadBytes(fileRef, imageBlob()));
  await assertSucceeds(getBytes(fileRef));
});

test('profile_pictures: unverified admin email is denied', async () => {
  await assertFails(
    getBytes(ref(unverifiedAdminStorage(), 'profile_pictures/user-1')),
  );
});

test('unscoped prefixes are admin-only', async () => {
  await assertFails(
    uploadBytes(ref(userStorage(), 'trips/user-1/photo.jpg'), imageBlob()),
  );
  await assertSucceeds(
    uploadBytes(ref(adminStorage(), 'trips/user-1/photo.jpg'), imageBlob()),
  );
});
