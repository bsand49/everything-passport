# mobile

Flutter application for Everything Passport on Android and iOS, backed by
Firebase Authentication, Cloud Firestore, and Firebase Storage.

> **Status:** Unreleased (`1.x`). See the root [README.md](../README.md),
> [CHANGELOG.md](../CHANGELOG.md), and [RELEASING.md](../RELEASING.md) for
> repository-level documentation.

## Features

- Email/password sign-up and sign-in, Google sign-in, and sign-out.
- `AuthService` support for password reset, account deletion, and email
  verification (`sendEmailVerification`, `reloadCurrentUser`).
- Automatic verification email on email/password sign-up, plus a persistent
  in-app banner on authenticated screens where unverified password users can
  resend the email or refresh their verification status. Email verification
  is required for admin access.
- Profile onboarding/editing for username, name, date of birth, nationality,
  public-profile preference, and photo.
- Transactional username uniqueness using the Firestore `usernames`
  collection.
- Profile photo upload to Firebase Storage at `profile_pictures/{userId}`.
- Country metadata from `metadata/countries` cached in memory with a
  24-hour TTL; Settings → Clear cache clears the metadata cache and
  downloaded images (Firestore offline persistence is left to the SDK).
- Material 3 UI and English (UK/US) localization delegates.
- Home/settings scaffolding; Add Trip and Add Event actions are placeholders
  for future travel-tracking features.

## Tech Stack

| Layer     | Technology                                                        |
| --------- | ----------------------------------------------------------------- |
| Framework | Flutter, Dart                                                     |
| Platforms | Android, iOS                                                     |
| State     | Provider, `StreamProvider`, Firebase auth/profile streams         |
| Backend   | Firebase Auth, Cloud Firestore, Firebase Storage, Google Sign-In  |
| Images    | `image_picker`, `image_cropper`, `cached_network_image`           |
| Testing   | `flutter_test`, `integration_test`, Mockito, `build_runner`, fakes |
| Quality   | `dart format`, `flutter analyze`, `flutter_lints`, Lefthook       |

## Prerequisites

- **Flutter SDK** `>=3.50.0` and **Dart SDK** `>=3.13.0`
- **JDK 21** for Android builds; CI uses Temurin 21 and Android Gradle Plugin
  `9.3.0`
- **Android Studio** for Android development and emulators
- **Xcode** on macOS for iOS development and simulators
- **Node.js/npm** at the repository root for Lefthook installation
- **Firebase CLI** and **FlutterFire CLI**:

  ```bash
  npm install -g firebase-tools
  dart pub global activate flutterfire_cli
  ```

## Getting Started

### 1. Install dependencies

From the repository root, install the Git hook tooling:

```bash
npm install
```

Then install Flutter dependencies:

```bash
cd mobile
flutter pub get
```

### 2. Configure Firebase

Firebase configuration files are gitignored and are not committed to the
repository:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options_dev.dart`
- `lib/firebase_options_prod.dart`

Firestore and Firebase Storage access is enforced by the repository-root
`firestore.rules` and `storage.rules`: regular users can only access their own
data, while admins listed in the `admins` collection can access everything.
See the root [README.md](../README.md#firebase-security-rules) for the deploy
command and access model.

Generate the development configuration with FlutterFire:

```bash
flutterfire configure \
  --project=everything-passport-dev \
  --platforms=android,ios \
  --android-package-name=com.bsand49.everything_passport \
  --ios-bundle-id=com.bsand49.everythingPassport \
  --out=lib/firebase_options_dev.dart \
  --yes
```

For a production configuration, repeat the command with the production
Firebase project and `--out=lib/firebase_options_prod.dart`. Note that
`lib/main.dart` currently aliases `ENV=prod` to the dev options until the
production file is generated and the TODO is resolved.

### 3. Platform-specific setup

#### Android

Google Sign-In on Android requires the app's SHA-1 fingerprint to be
registered in Firebase:

```bash
cd android
./gradlew signingReport
cd ..
```

Add the `debug` variant SHA-1 in the Firebase console, then download the
updated `google-services.json` into `android/app/`.

This project uses a modified `android/gradlew` to work around
`ANDROID_PREFS_ROOT` environment conflicts. Use `./gradlew` from `android/`
or let Flutter invoke the wrapper; do not rely on a global Gradle binary.

#### iOS/macOS

If `ios/Podfile` is missing from a fresh checkout, regenerate the platform
scaffolding first:

```bash
flutter create .
```

Then install CocoaPods dependencies:

```bash
cd ios
pod install
cd ..
```

On Apple Silicon Macs, use `arch -x86_64 pod install` if CocoaPods reports
compatibility issues.

Google Sign-In on iOS requires `ios/Runner/Info.plist` to register the OAuth
callback scheme: `CFBundleURLTypes` → `CFBundleURLSchemes` must contain the
`REVERSED_CLIENT_ID` from `ios/Runner/GoogleService-Info.plist` (e.g.
`com.googleusercontent.apps.<id>`). If `flutterfire configure` is re-run for
a different Firebase project, update the scheme to match the new plist — a
missing or mismatched scheme crashes the app when sign-in starts.

### 4. Run the app

The app requires compile-time `--dart-define` values:

| Variable           | Description                              | Allowed values | Default |
| ------------------ | ---------------------------------------- | -------------- | ------- |
| `ENV`              | Firebase environment selection           | `dev`, `prod`  | `dev`   |
| `SERVER_CLIENT_ID` | Google Sign-In web client ID             | String         | Required |

`SERVER_CLIENT_ID` can be found in `google-services.json` under the OAuth
client with `client_type` 3, or in Google Cloud Console under APIs & Services
> Credentials.

```bash
flutter run \
  --dart-define=ENV=dev \
  --dart-define=SERVER_CLIENT_ID=your-web-client-id
```

For IDE runs, configure the same `--dart-define` arguments in the launch
configuration. In VS Code, add them under `args` in `.vscode/launch.json`;
in Android Studio/IntelliJ, add them to the Flutter run configuration's
additional args field.

## Testing & Coverage

### Mock generation

Tests that use `@GenerateNiceMocks` require generated `*.mocks.dart` files.
After adding or changing mocked tests, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Use `--watch` while actively editing mock-dependent tests if needed.
Generated mocks are gitignored.

### Unit and widget tests

```bash
# All unit/widget tests
flutter test

# A directory or specific file
flutter test test/utils/
flutter test test/services/auth_service_test.dart

# Coverage report
flutter test --coverage
```

If `lcov` is installed, generate an HTML report:

```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Integration tests

Integration tests run on a physical device or emulator/simulator and cover
app boot, login/sign-up navigation, and shared validation behavior.

Prerequisites:

- A connected device or running emulator/simulator.
- `android/app/google-services.json` or `ios/Runner/GoogleService-Info.plist`.
- `SERVER_CLIENT_ID` supplied as a `--dart-define`.

```bash
flutter test \
  --dart-define=ENV=dev \
  --dart-define=SERVER_CLIENT_ID=your-web-client-id \
  integration_test/
```

`app_test.dart` is the smoke suite and needs real Firebase config plus
`SERVER_CLIENT_ID`. `google_sign_in_test.dart` and `auth_flow_test.dart`
run the real widget tree and services against fake plugin layers, so they
need no credentials but still run on a device/emulator.

If the app is already signed in on the device, the test attempts to sign out
first to establish a clean state.

## Linting & Formatting

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
```

Repository hooks run `dart format` on staged Dart files and `flutter analyze`
across the whole `mobile/` package before commit — a lint at any level,
including infos, in any file can block the commit. `flutter test --coverage`
with a `90%` LCOV threshold runs before push. See the root
[AGENTS.md](../AGENTS.md) for GUI Git client setup.

## Project Structure

```text
lib/
  exceptions/       Domain exceptions
  models/           Firestore/auth data models
  screens/          Login, sign-up, profile, home, and settings screens
  services/         Auth, profile, and metadata services
  theme/            AppTheme light/dark themes and brand colours
  utils/            Validators, date formatting, and image utilities
  widgets/          Reusable UI components
  main.dart         Firebase init, Provider graph, and auth routing
  firebase_options_dev.dart  Generated dev Firebase config (gitignored)
test/               Unit/widget tests mirroring lib/
assets/             Brand artwork (logo.svg source, PNG exports)
integration_test/   Device/emulator integration tests
android/            Android Gradle project
ios/                Xcode project
AGENTS.md           Flutter-specific repository conventions
```

## CI

`.github/workflows/build-and-test-mobile.yml` is path-filtered to `mobile/**`,
the workflow file itself, `.github/actions/**`, and the root `package.json` /
`package-lock.json` (mobile CI consumes the locked Firebase toolchain), then
runs:

1. `dart format --output=none --set-exit-if-changed .`
2. Firebase configuration via `.github/actions/configure-firebase`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter analyze`
5. `flutter test --coverage`
6. LCOV coverage reporting via `.github/actions/report-coverage`
7. Android emulator integration smoke test on API 31
8. iOS simulator integration smoke test on an available iPhone simulator
   (macOS runner)

Because the workflow is path-filtered, mobile checks do not run on PRs that
don't touch `mobile/`, the workflow/actions, or the root npm manifests — and
they are not required status checks, so treat failures on mobile PRs as
blocking manually.

Coverage fails below `MOBILE_COVERAGE_THRESHOLD`, which defaults to `90%`.

## Troubleshooting

### Android build issues

```bash
flutter clean
flutter pub get
```

If Gradle still fails, check that JDK 21 is active and that the project is
using the repository's `android/gradlew` wrapper.

### IDE reports "Entrypoint isn't within the current project"

1. Run `flutter pub get`.
2. In Android Studio/IntelliJ, choose **File > Sync Project with Gradle
   Files**.
3. Confirm the Flutter and Dart plugins are installed and enabled.

### iOS CocoaPods issues

```bash
rm -rf ios/Pods
rm ios/Podfile.lock
cd ios
pod repo update
pod install
cd ..
```

### Missing Firebase configuration

Regenerate the FlutterFire files with the commands above. Do not commit
`google-services.json`, `GoogleService-Info.plist`, or
`firebase_options_*.dart`; they are intentionally gitignored.
