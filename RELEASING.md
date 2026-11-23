# Releasing

This document describes the release strategy for everything-passport.

> **Status:** The application is **unreleased**. Source versions are currently
> `1.x` (`package.json` is `1.0.0`; `mobile/pubspec.yaml` is `1.0.0+1`), but no
> `v*` tags or GitHub Releases exist yet. The first tagged release will
> establish the public baseline.

## Versioning

The project follows [Semantic Versioning](https://semver.org/) with the
`v`-prefixed tag format `vMAJOR.MINOR.PATCH` (for example `v1.0.0`).

- `MAJOR` — breaking changes after the first stable release.
- `MINOR` — new features, backwards-compatible.
- `PATCH` — bug fixes, backwards-compatible.

### Version sources

- **Root `package.json`** — repository release version. Keep it aligned with
  the tag (without the `v` prefix). This package is private and only installs
  Lefthook.
- **`mobile/pubspec.yaml`** — mobile application version. Keep the semantic
  `MAJOR.MINOR.PATCH` portion aligned with the tag; the build number after `+`
  may advance independently for mobile builds.

`web/` is currently only a placeholder, so there are no separate backend or
web packages to version yet.

A single tag versions the whole repository.

## Changelog

[`CHANGELOG.md`](./CHANGELOG.md) follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Before releasing:

1. Move the contents of `[Unreleased]` into a new `## [X.Y.Z] - YYYY-MM-DD`
   section at the top of the releases list.
2. Add a link reference at the bottom of the file so version headings stay
   clickable:

   ```text
   [X.Y.Z]: https://github.com/bsand49/everything-passport/compare/vPREV...vX.Y.Z
   ```

   For the first release, link directly to the tag instead:

   ```text
   [X.Y.Z]: https://github.com/bsand49/everything-passport/releases/tag/vX.Y.Z
   ```

   Then update `[Unreleased]` to compare the release tag to `HEAD`. For the
   first release, use `vX.Y.Z...HEAD`; the compare link resolves once the tag
   is pushed.
3. Bump `"version"` in the root `package.json` and the semantic portion of
   `version` in `mobile/pubspec.yaml` to `X.Y.Z`.
4. Commit the release prep as `chore: release vX.Y.Z` on a
   `chore/release-vX.Y.Z` branch and merge it to `main` via pull request —
   version/config changes require a PR per `AGENTS.md`.

## Cutting a Release

There is no automated release workflow yet, so tags are created manually
after the release PR merges:

```bash
git checkout main
git pull

git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

Then create the GitHub Release:

1. Open the [Releases page](https://github.com/bsand49/everything-passport/releases).
2. Choose **Draft a new release** and select the pushed `vX.Y.Z` tag.
3. Set the title to `vX.Y.Z`.
4. Copy the matching `## [X.Y.Z]` section from `CHANGELOG.md` into the release
   notes.
5. Publish the release.

## Pre-release Checks

Run from `mobile/` before tagging:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test --coverage
flutter test \
  --dart-define=ENV=prod \
  --dart-define=SERVER_CLIENT_ID=<prod-web-client-id> \
  integration_test/app_test.dart
```

Before releasing to a Firebase project, deploy the current rules and verify
the `admins` allowlist is correct:

```bash
firebase deploy --only firestore:rules,storage --project <firebase-project-id>
```

Note that `ENV=prod` currently resolves to the development Firebase options
until `mobile/lib/firebase_options_prod.dart` is generated and the TODO in
`mobile/lib/main.dart` is resolved, so this smoke test exercises the dev
project for now.

The integration test requires a connected device or emulator with the native
Firebase config files and `SERVER_CLIENT_ID` supplied. Unit-test coverage
must remain at or above `90%` unless `MOBILE_COVERAGE_THRESHOLD` is changed.

Before tagging, also work through
[`docs/testing/manual-test-checklist.md`](./docs/testing/manual-test-checklist.md)
against a dev or prod build and record the results in the release PR.

## Building Release Artifacts

Mobile artifacts are built locally; there is no hosted deployment in this
repository yet.

```bash
cd mobile

flutter build apk --release \
  --dart-define=ENV=prod \
  --dart-define=SERVER_CLIENT_ID=<prod-web-client-id>

flutter build ipa --release \
  --dart-define=ENV=prod \
  --dart-define=SERVER_CLIENT_ID=<prod-web-client-id>
```

Before distributing production builds:

- Generate `lib/firebase_options_prod.dart` for the production Firebase
  project. `ENV=prod` currently falls back to the dev options until that file
  exists.
- Configure Android release signing. `android/app/build.gradle.kts` currently
  uses the debug signing config and has a TODO for release signing.
- Configure Apple signing/provisioning in Xcode for iOS distribution.

## Post-release

- Verify the GitHub Release notes and tag.
- Build and smoke-test the intended Android/iOS artifacts on a real device,
  covering the manual checklist in
  `docs/testing/manual-test-checklist.md`.
- Check that Firebase Auth, Firestore profile reads/writes, username
  uniqueness, and Storage uploads work against the intended environment.

## Hotfixes

For urgent fixes on a released version:

1. Branch from the release tag (or `main` if it is the latest).
2. Fix the issue, bump the patch version in `package.json` and
   `mobile/pubspec.yaml`, and update `CHANGELOG.md`.
3. Merge to `main`, tag `vX.Y.(Z+1)`, and push the tag.
4. Create a new GitHub Release and rebuild the affected mobile artifact.

## Rollback

If a critical issue is discovered immediately after tagging:

1. Delete the tag locally: `git tag -d vX.Y.Z`
2. Delete the tag remotely: `git push --delete origin vX.Y.Z`
3. Revert or fix the issue on a new branch, merge to `main`, and restart the
   release process with a new patch version.
