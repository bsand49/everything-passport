import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_ui/material_ui.dart';
import 'package:everything_passport/main.dart' as app;
import 'package:everything_passport/models/user_profile.dart';
import 'package:everything_passport/screens/home_screen.dart';
import 'package:everything_passport/screens/login_screen.dart';
import 'package:everything_passport/services/auth_service.dart';

import '../test/test_helper.dart';
import 'test_fakes.dart';

// Mock-backed end-to-end coverage for the Google Sign-In round trip: the real
// widget tree and AuthService run on device, while the GoogleSignIn and
// FirebaseAuth plugin layers are faked. This exercises the Dart-side path
// deterministically (credential construction, signInWithCredential, auth-state
// routing) without a real Google account; driving the native account picker
// itself is covered by manual/Maestro passes (see #60 and #64).

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late FakeGoogleSignIn fakeGoogleSignIn;
  late FakeUserProfileService fakeProfileService;
  late AuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeGoogleSignIn = FakeGoogleSignIn();
    fakeProfileService = FakeUserProfileService();
    authService = AuthService(auth: mockAuth, googleSignIn: fakeGoogleSignIn);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      app.MyApp(
        authService: authService,
        userProfileService: fakeProfileService,
        metadataService: FakeMetadataService(),
        cacheService: FakeCacheService(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Google Sign-In E2E (mocked plugin layer)', () {
    testWidgets('completes sign-in and routes to the home screen', (
      tester,
    ) async {
      fakeProfileService.emitProfile(
        UserProfile(
          userId: 'test_user',
          username: 'e2e_user',
          firstName: 'E2E',
          lastName: 'User',
        ),
      );
      await pumpApp(tester);
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      expect(fakeGoogleSignIn.authenticateCalls, 1);
      expect(mockAuth.currentUser, isNotNull);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('returns silently to the login screen on cancellation', (
      tester,
    ) async {
      fakeGoogleSignIn.authenticateError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
      await pumpApp(tester);
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      expect(fakeGoogleSignIn.authenticateCalls, 1);
      expect(mockAuth.currentUser, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('surfaces an error SnackBar on non-cancellation failure', (
      tester,
    ) async {
      fakeGoogleSignIn.authenticateError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
      );
      await pumpApp(tester);
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      expect(fakeGoogleSignIn.authenticateCalls, 1);
      expect(mockAuth.currentUser, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('Google Login Failed'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
