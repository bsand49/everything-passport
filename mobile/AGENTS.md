# mobile/

Flutter application package `everything_passport` for Android and iOS,
backed by Firebase Auth, Cloud Firestore, and Firebase Storage.

## Commands

Run these from `mobile/` unless noted otherwise:

```bash
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
flutter build apk --release --dart-define=ENV=prod --dart-define=SERVER_CLIENT_ID=<web-client-id>
flutter build ipa --release --dart-define=ENV=prod --dart-define=SERVER_CLIENT_ID=<web-client-id>
```

- JDK 21 is used for Android builds in CI; Android Gradle Plugin is `9.3.0`.
- `SERVER_CLIENT_ID` is required because `main()` passes it to
  `GoogleSignIn.instance.initialize`.
- `ENV=prod` currently falls back to the dev Firebase options until
  `lib/firebase_options_prod.dart` exists; see the TODO in `lib/main.dart`.

## Structure

- `lib/main.dart` — initializes Firebase/Google Sign-In, creates the Provider
  graph, and routes between login, profile onboarding, and home.
- `lib/screens/` — login, sign-up, profile, home, and settings screens.
- `lib/services/` — `AuthService`, `UserProfileService`, and
  `MetadataService`; these wrap Firebase/Auth/Firestore/Storage and accept
  optional Firebase dependencies for tests.
- `lib/models/` — Firestore-backed data models such as `UserProfile` and
  `Country`.
- `lib/widgets/` — reusable form, auth, profile, date-picker, and country
  UI components.
- `lib/utils/` — shared `Validators`, `DateFormatter`, and `ImageUtils`.
- `lib/exceptions/` — domain exceptions such as
  `UsernameAlreadyTakenException`.
- `test/` — unit/widget tests mirroring `lib/`; `test/test_helper.dart`
  provides reusable fakes and `createTestableWidget`.
- `integration_test/` — device/emulator smoke tests.
- `android/` and `ios/` — generated/native platform projects. Do not edit
  generated Firebase or plugin files by hand.

## State and data conventions

- Use Provider/`StreamProvider` for app state; screens should read services
  from context rather than constructing Firebase clients directly.
- Keep Firebase/Firestore/Storage access in `lib/services/` so screens and
  widgets stay testable.
- `UserProfileService` stores profiles in `userProfiles`, enforces username
  uniqueness through the `usernames` collection in a transaction, and uploads
  photos to `profile_pictures/{userId}`.
- `MetadataService` reads `metadata/countries` and caches the result in
  memory; use `forceRefresh` when a fresh read is required.
- Usernames are normalized to lowercase before uniqueness checks and storage.

## Firebase configuration

These files are gitignored and must be generated locally or by CI:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options_dev.dart`
- `lib/firebase_options_prod.dart`

Generate dev configuration with `flutterfire configure` (see `README.md`).
CI uses `.github/actions/configure-firebase`; without Firebase secrets it
creates dummy options so formatting, analysis, and unit tests can run.

Firestore/Storage access is enforced by the repository-root
`firestore.rules` and `storage.rules`: owner-only for regular users, full
access for `admins` collection members. New collections or storage prefixes
need matching rule updates in the same change.

## Testing

- Prefer `flutter_test` unit/widget tests under `test/` mirroring `lib/`.
- Use the fakes in `test/test_helper.dart` for common service/widget tests;
  use Mockito/generated mocks where the existing suite already does.
- `*.mocks.dart` files are generated and gitignored. After changing
  `@GenerateNiceMocks` or mock-dependent tests, run
  `dart run build_runner build --delete-conflicting-outputs`.
- Integration tests require a device/emulator, native Firebase config files,
  and `SERVER_CLIENT_ID`; they sign out first when needed to keep a clean
  auth state.
- CI coverage excludes tests, generated mocks, generated Firebase options,
  and build output. Keep line coverage at or above `90%`.

## Platform notes

- Android uses Gradle Kotlin DSL with AGP `9.3.0`, Kotlin `2.3.20`, compile
  SDK `37`, and Java/Kotlin JVM target `17`; CI still runs JDK 21.
- Android release builds currently use the debug signing config and contain a
  TODO for release signing — configure a real upload keystore before
  distributing store builds.
- iOS requires Xcode/CocoaPods setup and Apple signing for device or App Store
  builds.
- The modified root `android/gradlew` setup is intentional for this project;
  use the Flutter/Gradle wrapper rather than a global Gradle binary.
