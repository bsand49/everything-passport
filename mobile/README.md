# Everything Passport - Mobile Client

A cross-platform travel companion app designed to help users gamify and track their life experiences. Built with Flutter and Firebase.

## Prerequisites

Before you begin, ensure you have the following installed:

*   **Flutter SDK**: Follow the [official installation guide](https://docs.flutter.dev/get-started/install) for your OS.
*   **Java Development Kit (JDK)**: Version 17 is required for Android builds.
*   **Android Studio**: For Android development and emulators.
*   **Xcode** (macOS only): For iOS/macOS development and simulators.
*   **Firebase CLI**: For managing Firebase configurations. Install via npm: `npm install -g firebase-tools`.

## Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/[your-repo]/everything-passport.git
cd everything-passport/mobile
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Platform-Specific Setup

#### macOS (iOS)
Install CocoaPods dependencies:
```bash
cd ios
pod install
cd ..
```
*Note: If you are on an Apple Silicon (M1/M2/M3) Mac, you may need to run `arch -x86_64 pod install` if you encounter compatibility issues.*

### 4. Firebase Configuration
The Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`, and `firebase_options.dart`) are **not** included in the repository for security reasons.

To set up Firebase locally:
1.  **Install FlutterFire CLI**:
    ```bash
    dart pub global activate flutterfire_cli
    ```
2.  **Login to Firebase**:
    ```bash
    firebase login
    ```
3.  **Configure the project**:
    - **Development**:
      ```bash
      flutterfire configure --out=lib/firebase_options_dev.dart
      ```
    - **Production (Optional)**:
      ```bash
      flutterfire configure --out=lib/firebase_options_prod.dart
      ```
    Follow the prompts to select/create your Firebase project and platforms. This will generate the necessary configuration files (including the environment-specific Dart options expected by the app).

### 5. Google Sign-In Setup (Android)
To use Google Sign-In on the Android emulator or a physical device:
1.  **Generate SHA-1 Fingerprint**:
    ```bash
    cd android && ./gradlew signingReport
    ```
2.  **Register Fingerprint**: Add the `SHA1` from the `debug` variant to your project in the [Firebase Console](https://console.firebase.google.com/).
3.  **Update Config**: Download the updated `google-services.json` and replace the one in `android/app/`.

## Development Environment Notes

### Android Gradle Wrapper
This project uses a modified `gradlew` script to resolve environment variable conflicts (`ANDROID_PREFS_ROOT`). Always use `./gradlew` from the `android/` directory (or let Flutter handle it) rather than calling a global Gradle binary.

### IDE Setup (Android Studio / IntelliJ)
If you see the error **"Entrypoint isn't within the current project"**:
1.  Run `flutter pub get`.
2.  Click **File > Sync Project with Gradle Files**.
3.  Ensure the **Flutter** and **Dart** plugins are installed and configured.

## Starting Emulators and Simulators

Before running `flutter run`, you must have a target device (physical or virtual) active.

### Android Emulator
*   **Via Android Studio**: Open **Tools > Device Manager**, select a virtual device, and click the **Play** button.
*   **Via Command Line**:
    ```bash
    # List available emulators
    flutter emulators
    
    # Launch a specific emulator (replace <id> with your emulator id)
    flutter emulators --launch <id>
    ```

### iOS Simulator (macOS only)
*   **Via Xcode**: Open **Xcode > Open Developer Tool > Simulator**.
*   **Via Command Line**:
    ```bash
    open -a Simulator
    ```

## Running the Application

### Environment Configuration

The application requires specific environment variables to be set at build time using the `--dart-define` flag.

| Variable           | Description                                               | Allowed Values                   | Default    |
|:-------------------|:----------------------------------------------------------|:---------------------------------|:-----------|
| `ENV`              | The target environment (affects Firebase initialization). | `dev`, `prod`                    | `dev`      |
| `SERVER_CLIENT_ID` | The Google Sign-In Web Client ID.                         | String from Firebase/GCP Console | (Required) |

> [!NOTE]
> You can find the `SERVER_CLIENT_ID` in the `google-services.json` file (as `client_id` under `oauth_client` with `client_type` 3) or in the Google Cloud Console under APIs & Services > Credentials.

### From the Command Line
To run on a connected device or emulator with the required environment variables:
```bash
flutter run --dart-define=ENV=dev --dart-define=SERVER_CLIENT_ID=your-client-id
```

### From an IDE
*   **Android Studio / IntelliJ**: Select your device in the toolbar and press the **Run** icon (or `Shift + F10` / `Control + R`).
*   **VS Code**: Press `F5` or use the "Run and Debug" panel.

## Testing

This project includes unit tests for business logic and services.

### Code Generation for Mocks
This project uses `mockito` for unit testing, which requires code generation. If you add or modify tests that use `@GenerateMocks`, you must generate the mock files before running your tests.

Run the build runner command to generate the mocks:
```bash
dart run build_runner build --delete-conflicting-outputs
```

*Note: You can add `--watch` to the command to continuously regenerate mocks as you edit test files.*


### Running Unit Tests
To execute all unit tests from the root directory:
```bash
flutter test
```

To run a specific test file:
```bash
flutter test test/services/auth_service_test.dart
```

To view test coverage (requires `lcov`):
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Running Integration Tests
Integration tests run on real devices or emulators and cover end-to-end flows.

**Prerequisites:**
- A connected physical device or a running emulator/simulator.
- Native configuration files (`google-services.json` or `GoogleService-Info.plist`) correctly placed in the native directories.

To run all integration tests:
```bash
flutter test integration_test/app_test.dart
```

To run tests with a specific environment configuration (e.g., Production):
```bash
flutter test --dart-define=ENV=prod integration_test/app_test.dart
```

## Project Structure
*   `lib/main.dart`: Entry point and authentication wrapper.
*   `lib/services/`: Business logic and API clients (e.g., `AuthService`).
*   `lib/screens/`: UI screens (Login, Sign Up, Home).
*   `lib/firebase_options_dev.dart`: Firebase configuration for the development environment.
*   `lib/firebase_options_prod.dart`: (Optional) Firebase configuration for the production environment.

## Troubleshooting

### Android Build Issues
If you encounter Gradle errors, try cleaning the build:
```bash
flutter clean
flutter pub get
```

### iOS CocoaPods Issues
If `pod install` fails, try:
```bash
rm -rf ios/Pods
rm ios/Podfile.lock
cd ios
pod repo update
pod install
cd ..
```

---
For more help, visit the [Flutter Documentation](https://docs.flutter.dev/).
