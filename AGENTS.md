# everything-passport

Flutter mobile app (`mobile/`) plus repository-level Node/Lefthook tooling and
GitHub automation. There is no custom backend yet; `web/` is reserved for a
future web frontend, and Firebase provides the current backend services.

`mobile/AGENTS.md` contains Flutter-specific rules — check it when working
inside `mobile/`.

## Structure

- `mobile/` — the implemented Flutter app for Android and iOS. Firebase Auth,
  Cloud Firestore, and Firebase Storage provide the current backend services.
- `web/` — reserved placeholder for a future web frontend; it currently
  contains only `.gitkeep`.
- `.github/actions/` — composite actions for Firebase configuration and LCOV
  coverage reporting.
- `.github/workflows/` — build/test, branch-name, Dependabot, and auto-merge
  automation.
- `package.json` / `package-lock.json` — root npm manifest used only to install
  Lefthook; this is not a JavaScript application.
- `lefthook.yml` — Git hook commands for formatting, analysis, tests, and
  coverage.
- `firebase.json`, `firestore.rules`, `storage.rules` — Firebase CLI deploy
  config and owner/admin security rules.
- `CHANGELOG.md`, `README.md`, `RELEASING.md`, `AGENTS.md` — repository
  documentation.

## Commands

Run Flutter commands from `mobile/`:

```bash
# From the repository root
npm install

# From mobile/
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test
flutter test --coverage
flutter test \
  --dart-define=ENV=dev \
  --dart-define=SERVER_CLIENT_ID=<web-client-id> \
  integration_test/app_test.dart
flutter run --dart-define=ENV=dev --dart-define=SERVER_CLIENT_ID=<web-client-id>
```

`SERVER_CLIENT_ID` is required at runtime for Google Sign-In. Generated
Firebase files and `*.mocks.dart` files are gitignored; regenerate them with
`flutterfire configure` and `build_runner` rather than committing them.

## Git hooks

Lefthook is installed by the root `prepare` script (`npm install`).

- `pre-commit`: `dart format` on staged Dart files and
  `flutter analyze --no-fatal-infos`.
- `pre-push`: `flutter test --coverage`, then checks `mobile/coverage/lcov.info`
  against a `90%` line-coverage threshold.

GUI Git clients can use the gitignored `lefthook-local.yml` to source a shell
profile or extend `PATH` so hooks can find Flutter.

For macOS/Linux, the simplest option is:

```yaml
rc: /Users/yourname/.zprofile
```

If sourcing the profile is insufficient, extend `PATH` explicitly for each
hook command, for example:

```yaml
pre-commit:
  commands:
    format:
      env:
        PATH: "/path/to/flutter/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:#{ENV['PATH']}"
    analyze:
      env:
        PATH: "/path/to/flutter/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:#{ENV['PATH']}"

pre-push:
  commands:
    mobile-tests:
      env:
        PATH: "/path/to/flutter/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:#{ENV['PATH']}"
```

On Windows Git Bash/WSL, the `rc` approach also works; native Windows clients
may need the Flutter `bin` directory appended to `PATH` instead, for example
`PATH: "%PATH%;C:\\path\\to\\flutter\\bin"`.

## Releasing

See `RELEASING.md` for the full process. Keep the release version in the root
`package.json` and the semantic version in `mobile/pubspec.yaml` aligned with
the `vMAJOR.MINOR.PATCH` tag; the pubspec build number after `+` may advance
independently for mobile builds.

## Firebase

- Runtime configuration is selected by `--dart-define=ENV=dev|prod`.
- `SERVER_CLIENT_ID` is passed to `GoogleSignIn.instance.initialize`.
- Generated files (`google-services.json`, `GoogleService-Info.plist`, and
  `firebase_options_*.dart`) are gitignored and must never be committed.
- CI uses `.github/actions/configure-firebase`, which runs `flutterfire
  configure` when Firebase secrets are present and generates dummy options for
  builds that do not need live Firebase.
- Current Firestore collections used by the app are `userProfiles` (with a
  `trips` subcollection), `usernames`, and `metadata` (`metadata/countries`);
  profile images are stored at `profile_pictures/{userId}` in Firebase Storage.
- `firestore.rules` and `storage.rules` enforce owner-only access for regular
  users and full access for admins listed in the `admins` collection (doc IDs
  are admin email addresses). Profile/trip writes must pass the field
  validation functions in `firestore.rules`; storage uploads must be images
  under 5 MB. Any unscoped collection or storage prefix is admin-only by
  default.
- Deploy rules with `firebase deploy --only firestore:rules,storage
  --project everything-passport-dev` from the repository root. Bootstrap the
  first `admins/{email}` document through the Firebase console or Admin SDK;
  clients cannot create admin entries.

## Conventions

- **Formatting/analysis**: run `dart format` and `flutter analyze` before
  pushing Flutter changes. The pre-commit hook uses
  `flutter analyze --no-fatal-infos`; CI runs `flutter analyze`.
- **Tests**: `test/` mirrors `lib/`; use `test/test_helper.dart` fakes for
  widget/service tests where possible. Mockito mocks are generated and ignored
  — run `build_runner` after changing `@GenerateNiceMocks` tests.
- **Coverage**: keep mobile line coverage at or above `90%`; CI can override
  the threshold with `MOBILE_COVERAGE_THRESHOLD`.
- **Firebase rules**: when adding Firestore collections/subcollections or
  Firebase Storage prefixes, update `firestore.rules`/`storage.rules` in the
  same change. Prefer owner-scoped paths containing the user's UID and keep
  the admin-only secure default for anything not explicitly scoped.
- **Changelog**: record notable user-facing or structural changes in
  `CHANGELOG.md` under `[Unreleased]` as part of the same change. Update
  `README.md` when documented behavior, setup, or project structure changes.
- **Branch names**: PR branches must satisfy `branch-name-check.yml` —
  `<prefix>/<description>` or `<prefix>/<issue-id>-<description>`, where the
  prefix is `feat`, `fix`, `refactor`, `docs`, `ci`, `test`, or `chore`.
- **Committing**: changes to code, config, CI workflows, dependencies, or
  infrastructure go on a `<prefix>/<description>` branch and through a PR.
  Documentation-only changes (`*.md`) may be committed directly to `main`.
- **Merged PRs**: after merge, delete the remote and local branch (`git push
  origin --delete <branch>`, `git branch -d <branch>`, then `git fetch
  --prune`).
- **PR review comments**: reply inline on the specific review-comment thread
  rather than posting a new top-level comment.
- **Action versions**: follow the existing workflow style — GitHub-owned
  actions use major version tags, and third-party workflow actions that are
  already SHA-pinned should remain pinned.
- **Code ownership**: `.github/CODEOWNERS` assigns `@bsand49` as the owner of
  all files.
