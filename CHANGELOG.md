# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note:** This application is unreleased. No `v*` tags or GitHub Releases
> have been published yet; the first tagged release will establish the public
> version baseline.

## [Unreleased]

### Added

- Initial project infrastructure for the Flutter mobile app, repository docs,
  Git hooks, CI automation, and a reserved `web/` placeholder.
- Flutter mobile application foundation:
  - Core app structure, navigation, Material 3 UI, and en-GB/en-US
    localization.
  - Firebase Authentication with email/password, Google Sign-In, and sign-out;
    the auth service also supports password reset and account deletion.
  - Cloud Firestore profile storage, transactional username uniqueness, and
    country metadata loading.
  - Firebase Storage profile-picture uploads.
  - Image picking/cropping and cached remote images.
- Testing infrastructure:
  - `flutter_test` unit/widget suite with Mockito and generated mocks.
  - `integration_test` smoke suite for app boot, auth navigation, and shared
    validation behavior.
  - `build_runner` mock generation.
  - `tests/rules/` Firebase emulator suite covering Firestore and Storage
    security rules (owner/admin access, field validation, and secure
    defaults), run in CI by `rules-tests.yml`.
- Repository management:
  - `CODEOWNERS` for review assignment.
  - Dependabot configuration for GitHub Actions, npm, and pub updates.
  - Dependabot auto-merge workflow for approved safe update groups.
  - Firebase `firestore.rules` and `storage.rules` with a root `firebase.json`
    deploy config; rules preserve the existing username/profile/trip validation
    and enforce owner-only user access plus admin access via the `admins`
    collection. Admin access additionally requires a verified email, and
    username mappings can only be created alongside a matching profile write,
    preventing username squatting, and username changes must release the
    previous mapping in the same transaction.
  - Lefthook pre-commit formatting/analysis and pre-push test/coverage checks,
    including local GUI-client overrides.
  - Pull request template and branch-name enforcement workflow.
- Documentation:
  - `CHANGELOG.md` for release history.
  - Root `RELEASING.md` for the release process.
  - Root and `mobile/` `AGENTS.md` files for repository and Flutter-specific
    conventions.
  - Detailed root and mobile READMEs covering setup, testing, CI, Firebase
    configuration, and troubleshooting.
  - `docs/` directory with a manual test checklist template
    (`docs/testing/manual-test-checklist.md`) referenced by `RELEASING.md`.
- Utility layer:
  - Shared `Validators`, `DateFormatter`, and `ImageUtils` utilities.
  - Unit tests for utilities and refactored screens/widgets to use shared
    logic.
- Country flags integration:
  - `country_flags` package support.
  - Circular flags and dynamic prefix icons in `CountryAutocomplete`.
  - Unit tests for flag rendering and interactions.
- Flutter 3.50 toolchain migration:
  - Minimum Flutter SDK raised to `>=3.50.0`.
  - All `package:flutter/material.dart` imports migrated to
    `package:material_ui/material_ui.dart`, clearing the Flutter 3.47+
    deprecation diagnostics; localization delegates now come from
    `GlobalMaterialLocalizations.delegates`.
- Email verification for password accounts:
  - A verification email is sent automatically after email/password sign-up;
    the account is still created if the send fails, and sign-up surfaces a
    distinct `EmailVerificationSendException` so the UI can say the email
    was not sent instead of claiming it was.
  - `AuthService` exposes `sendEmailVerification()` and
    `reloadCurrentUser()`, and detects unverified password accounts via
    `requiresEmailVerificationFor` (Google sign-in accounts are already
    verified). The auth stream uses `userChanges()` so reload-updated
    verification status reaches the UI.
  - A persistent in-app banner on the home, profile, settings, and edit
    profile screens prompts unverified password users to verify, with resend
    and refresh-status actions. Email verification is required for admin
    access.
- CI updates:
  - `.github/workflows/build.yml` renamed to
    `build-and-test-mobile.yml` and now uses workflow-level `paths` filters
    instead of a `detect-changes` job; branch triggers normalized to `main`.
  - Added an iOS simulator integration smoke job (macOS runner) alongside the
    existing Android emulator smoke test.
  - `configure-firebase` now also generates a dummy
    `GoogleService-Info.plist` for builds without Firebase secrets.
  - `rules-tests.yml` branch filter normalized to `main`, now runs on every
    PR so its required status check always reports, and gained a `push`
    trigger for post-merge validation.

### Fixed

- iOS Google Sign-In crashed when started because `ios/Runner/Info.plist`
  lacked the `CFBundleURLTypes` entry for the OAuth reversed client ID
  scheme.
- Google Sign-In failures that are not user cancellations (for example
  configuration errors) now surface an error message instead of returning
  silently.

### Security

- Added npm `overrides` in the root and `tests/rules` manifests to force
  patched transitive dependencies (`uuid`, `glob`, `@opentelemetry/core`, and
  `@grpc/grpc-js`), clearing `npm audit` findings that Dependabot could not
  resolve within `firebase-tools`/`firebase` version constraints.

<!-- Link references for version headings above -->

[Unreleased]: https://github.com/bsand49/everything-passport/compare/main...HEAD
