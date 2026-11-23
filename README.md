# everything-passport

Travel companion app for gamifying and tracking life experiences, travels,
and hobbies. The implemented application is a Flutter mobile app for Android
and iOS, backed by Firebase Authentication, Cloud Firestore, and Firebase
Storage. The repository also contains the root tooling used for Git hooks and
GitHub automation. There is no custom backend yet; `web/` is reserved for a
future web frontend, and Firebase provides the current backend services.

> **Status:** Unreleased (`1.x`). See [CHANGELOG.md](./CHANGELOG.md) for the
> release history and [RELEASING.md](./RELEASING.md) for the release process.

## Features

The mobile app currently implements Firebase Auth (email/password and Google
sign-in), profile onboarding/editing with transactional username uniqueness,
profile photo uploads to Firebase Storage, and country metadata backed by
Firestore. Add Trip and Add Event are placeholders for future travel-tracking
features. See [mobile/README.md](./mobile/README.md#features) for the detailed
feature list.

## Prerequisites

- **Node.js/npm** for the repository-level Lefthook install and the
  `tests/rules` Firebase emulator suite
- **Firebase CLI** and **FlutterFire CLI** for Firebase configuration:

  ```bash
  npm install -g firebase-tools
  dart pub global activate flutterfire_cli
  ```

Mobile toolchain requirements (Flutter/Dart SDK, JDK, Android Studio, Xcode)
are listed in [mobile/README.md](./mobile/README.md#prerequisites).

The root and `tests/rules` `package.json` files use npm `overrides` to pin
patched transitive dependencies (`uuid`, `glob`, `@opentelemetry/core`, and
`@grpc/grpc-js`) that `firebase-tools`/`firebase` version constraints
currently block. See `AGENTS.md` for when these overrides can be revisited.

## Getting Started

From the repository root, install the Git hook tooling, then install Flutter
dependencies:

```bash
npm install
cd mobile
flutter pub get
```

Firebase configuration, platform-specific setup (SHA-1 fingerprints, CocoaPods,
IDE run configs), and running the app are covered in
[mobile/README.md](./mobile/README.md#getting-started).

## Testing & Coverage

The Flutter app's test suite is documented in
[mobile/README.md](./mobile/README.md#testing--coverage). Firebase security
rules have their own emulator suite in `tests/rules/`:

```bash
npm --prefix tests/rules install
npx firebase emulators:exec --only firestore,storage \
  --project demo-everything-passport 'npm --prefix tests/rules test'
```

CI runs `flutter test --coverage` plus Android emulator and iOS simulator
integration smoke tests when `mobile/` changes. The `report-coverage`
composite action parses `mobile/coverage/lcov.info`, posts a sticky PR
comment, writes to the job summary, and fails below
`MOBILE_COVERAGE_THRESHOLD` (default `90%`).

## Git Hooks

Git hooks are managed by **Lefthook** and installed by the root `prepare`
script when `npm install` runs at the repository root:

- `pre-commit`: `dart format` on staged Dart files and
  `flutter analyze`
- `pre-push`: `flutter test --coverage` plus a `90%` LCOV coverage threshold

For GUI Git clients that cannot find Flutter, create the gitignored
`lefthook-local.yml` file described in [AGENTS.md](./AGENTS.md).

## Project Structure

```text
mobile/                  Flutter app for Android/iOS — see mobile/README.md
  lib/                   App source (screens, services, models, widgets)
  test/                  Unit/widget tests mirroring lib/
  integration_test/      Device/emulator integration tests
web/                     Reserved placeholder for a future web frontend
.github/
  actions/               Composite actions for Firebase config and coverage
  workflows/             CI and Dependabot automation
firebase.json            Firebase CLI deploy config for security rules
firestore.rules          Firestore owner/admin access rules
storage.rules            Firebase Storage owner/admin access rules
tests/rules/             Firebase emulator tests for the security rules
docs/                    Project docs — see docs/AGENTS.md
package.json             Root Lefthook dependency only
package-lock.json        Root npm lockfile
lefthook.yml             Git hook configuration
CHANGELOG.md             Release history
README.md                This file
RELEASING.md             Release process
AGENTS.md                Repository conventions for coding agents
```

## CI/CD

All automation lives in [`.github/`](.github/):

| Workflow                    | Trigger                                | Purpose                                                        |
| --------------------------- | -------------------------------------- | -------------------------------------------------------------- |
| `build-and-test-mobile.yml` | PRs and pushes to `main` touching `mobile/`, the workflow, or `.github/actions/` | Formats, analyzes, tests, and smoke-tests the Flutter app on Android emulator and iOS simulator |
| `rules-tests.yml`           | PRs and pushes to `main`                       | Runs the Firebase emulator suite for Firestore/Storage security rules |
| `branch-name-check.yml`     | PRs                                    | Enforces `<prefix>/(<issue-id>-)<description>` branch names    |
| `dependabot-auto-merge.yml` | Dependabot PR lifecycle/reviews        | Auto-merges approved safe dependency-update groups             |

`dependabot.yml` is not a workflow; it configures weekly GitHub Actions, npm,
and pub dependency updates.

Deployment and release details are documented in [RELEASING.md](./RELEASING.md).
There is currently no hosted web/backend deployment.

## Configuration

The app uses compile-time `--dart-define` variables (`ENV`, `SERVER_CLIENT_ID`)
rather than `.env` files, and generated Firebase configuration files are
gitignored. See [mobile/README.md](./mobile/README.md) for the full list and
setup commands.

### Firebase Security Rules

`firestore.rules` and `storage.rules` at the repository root enforce the data
access model:

- Regular users can only read/write their own `userProfiles/{uid}` document
  and `userProfiles/{uid}/trips/{tripId}` subcollection. Profile writes must
  pass field validation and keep a consistent `usernames/{username}` mapping
  (admins bypass the validators so they can repair data).
- `usernames` mappings may only be created for the authenticated user's UID,
  cannot overwrite an existing username, and cannot be listed by regular users.
- `metadata` (e.g. `metadata/countries`) is readable by signed-in users and
  writable by admins.
- Firebase Storage profile pictures live at `profile_pictures/{userId}` (one
  object per user, no extension) and are owner-scoped by UID path, limited to
  image uploads under 5 MB.
- Admins are allowlisted in the `admins` Firestore collection, keyed by email
  address, and can access all data. Bootstrap the first admin document through
  the Firebase console or Admin SDK; client writes cannot escalate privileges.
- Any collection or storage prefix not explicitly scoped is admin-only by
  default.

Deploy rules to the dev project with:

```bash
npx firebase deploy --only firestore:rules,storage --project everything-passport-dev
```

### Bootstrapping an admin

Admin access is controlled by the `admins` collection, keyed by the user's
email address. To grant admin access to an existing user:

1. Deploy the rules above.
2. In the Firebase console, open **Firestore Database** and create a document
   in the `admins` collection whose document ID is the user's exact email
   address as shown in Firebase Authentication (the rules compare it to
   `request.auth.token.email`).
3. The document body can be empty, or include metadata such as `role` or
   `createdAt` for your own reference — the rules only check that the document
   exists.

Client apps cannot create `admins` documents, so this step must be done through
the Firebase console or the Admin SDK. The admin account's email must be
verified — the rules require `email_verified`, which Google sign-in satisfies
automatically while email/password users must complete verification. If a
user's email changes, the `admins/{email}` document must be updated to match.

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).
