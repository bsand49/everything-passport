# integration_test/

On-device integration tests run via `flutter test` against a connected
device/emulator/simulator — they are not part of the plain `flutter test`
unit/widget run, which only covers `test/`.

## Files

- `app_test.dart` — smoke suite. Calls `app.main()`, so it needs real
  Firebase config files and a valid `SERVER_CLIENT_ID`; it signs out first
  when needed to establish a clean auth state.
- `google_sign_in_test.dart` — deterministic Google Sign-In coverage. Pumps
  `MyApp` with injected services: the real `AuthService` backed by
  `MockFirebaseAuth` (`firebase_auth_mocks`) and the shared `GoogleSignIn`
  fakes, plus the service fakes from `test/test_helper.dart`. No Firebase
  initialization or `SERVER_CLIENT_ID` is required for these tests.
- `auth_flow_test.dart` — email/password sign-in round trip and the
  `AuthWrapper` routing matrix (complete profile → home, missing/incomplete
  profile → onboarding), using the same mocked-plugin-layer approach.
- `test_fakes.dart` — shared `GoogleSignIn`/account/authorization-client
  fakes used by the mock-backed tests; not a `*_test.dart` file, so
  `flutter test` does not run it directly.

## Conventions

- Run from `mobile/`:

  ```bash
  flutter test \
    --dart-define=ENV=dev \
    --dart-define=SERVER_CLIENT_ID=<web-client-id> \
    integration_test/
  ```

  The dart-defines are only needed by `app_test.dart`; the directory target
  runs both files.
- Reuse the fakes in `test/test_helper.dart` via the relative import
  `../test/test_helper.dart` rather than duplicating them.
- `google_sign_in_mocks` cannot cover `AuthService.signInWithGoogle`: its
  account fake does not implement the v7 `authorizationClient` API the
  service relies on. Keep or extend the fakes in `test_fakes.dart` instead
  of adding generated mocks (which would require `build_runner` in the CI
  smoke jobs).
- Driving the real native Google account picker is out of scope for
  `flutter test` — it is manual/Maestro territory tracked in #64. Keep
  widget-level tests on the mocked plugin layer.
- General Flutter conventions (format/analyze/coverage thresholds,
  Provider-based state) live in `../AGENTS.md`.
