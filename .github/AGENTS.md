# .github/

GitHub Actions automation: composite actions under `actions/` and workflows
under `workflows/`. Root `AGENTS.md` covers repo-wide conventions; this file
covers CI-specific ones.

## Actions

- `actions/configure-firebase` — composite action that installs the
  locked toolchain via `npm ci` at the repo root (so `firebase-tools`
  resolves exactly as `package-lock.json`, including the security
  `overrides`) with `node_modules/.bin` on `PATH`, installs
  `flutterfire_cli`, then runs `flutterfire configure` when
  `FIREBASE_SERVICE_ACCOUNT_JSON` is set or writes dummy Firebase config
  otherwise. It runs on the Ubuntu build job; the iOS smoke job repeats
  the `npm ci` + PATH setup on macOS for its own configure step.
- `actions/report-coverage` — uploads `mobile/coverage/lcov.info` to the
  coverage reporter.

## Workflows

- `build-and-test-mobile.yml` — path-filtered to `mobile/**`, the workflow
  file itself, `.github/actions/**`, and the root `package.json` /
  `package-lock.json` (mobile CI consumes the locked Firebase toolchain).
  Three jobs: `build-and-test-mobile`
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
- **Firebase CLI in workflows**: never `npm install -g firebase-tools` —
  global installs bypass `package-lock.json` and the security `overrides`.
  Run `npm ci` at `$GITHUB_WORKSPACE` and put `node_modules/.bin` on
  `PATH`/`GITHUB_PATH` instead (see `actions/configure-firebase`). Any job
  doing this must `actions/setup-node` with `node-version: '26'` (matching
  `rules-tests.yml`) rather than relying on the runner's default Node.
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
- **Mobile smoke jobs are advisory**: `smoke-test-mobile-android` and
  `smoke-test-mobile-ios` in `build-and-test-mobile.yml` are intentionally
  not required checks (decision for #45). Making them enforceable would
  require an always-run gate job that self-skips on non-mobile changes; that
  mechanism is deferred unless the smoke jobs prove flaky enough to need it.
- **iOS smoke runner**: `macos-latest`. The static `ios/Flutter/` templates
  must be tracked in git — see `mobile/AGENTS.md` platform notes.
