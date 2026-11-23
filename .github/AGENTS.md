# .github/

GitHub Actions automation: composite actions under `actions/` and workflows
under `workflows/`. Root `AGENTS.md` covers repo-wide conventions; this file
covers CI-specific ones.

## Actions

- `actions/configure-firebase` — composite action that installs
  `firebase-tools` (exact-pinned to the root `package-lock.json` version,
  currently `15.37.0`) and `flutterfire_cli`, then runs `flutterfire
  configure` when
  `FIREBASE_SERVICE_ACCOUNT_JSON` is set or writes dummy Firebase config
  otherwise. It runs on the Ubuntu build job.
- `actions/report-coverage` — uploads `mobile/coverage/lcov.info` to the
  coverage reporter.

## Workflows

- `build-and-test-mobile.yml` — path-filtered to `mobile/**`, the workflow
  file itself, and `.github/actions/**`. Three jobs: `build-and-test-mobile`
  (Ubuntu: format, Firebase config, build_runner, analyze, tests, coverage),
  `smoke-test-mobile-android`, and `smoke-test-mobile-ios` (both download
  the `firebase-config` artifact produced by the build job).
- `rules-tests.yml` — Firebase emulator tests for `firestore.rules` and
  `storage.rules`; uses `npm ci` so it gets the locked `firebase-tools`.
- `branch-name-check.yml`, `dependabot-auto-merge.yml` — PR hygiene.

## Conventions and gotchas

- **Secrets**: jobs that need Firebase credentials declare
  `environment: dev`; secrets are not shared across environments.
- **Apple Firebase files**: `flutterfire configure` only writes
  `GoogleService-Info.plist` on macOS (`Platform.isMacOS` guard in
  flutterfire_cli). The Ubuntu job cannot produce it — the iOS smoke job
  re-runs configure on the macOS runner when credentials exist.
- **Global installs in workflows** are not covered by `npm ci`; pin
  `firebase-tools` to the exact version in `package-lock.json` (`15.37.0`)
  so CI can't drift from the locked toolchain.
- **Artifact handoff**: `firebase-config` carries
  `firebase_options_*.dart`, `google-services.json`, and
  `GoogleService-Info.plist` (when generatable) from the build job to both
  smoke jobs.
- **Action pinning**: GitHub-owned actions use major version tags;
  third-party actions that are already SHA-pinned stay pinned.
- **Path-filtered workflows and required checks**: a workflow skipped by
  `paths`/`branches` filters reports no check run, so its jobs cannot be
  required status checks (they'd stay Pending and block merges). Only
  always-run workflows — or jobs that always execute and self-skip — may be
  listed in the Main Branch Protection ruleset.
- **iOS smoke runner**: `macos-latest`. The static `ios/Flutter/` templates
  must be tracked in git — see `mobile/AGENTS.md` platform notes.
