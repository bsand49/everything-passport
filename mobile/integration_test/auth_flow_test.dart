import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:everything_passport/main.dart' as app;
import 'package:everything_passport/models/user_profile.dart';
import 'package:everything_passport/screens/home_screen.dart';
import 'package:everything_passport/screens/login_screen.dart';
import 'package:everything_passport/screens/user_profile_screen.dart';
import 'package:everything_passport/services/auth_service.dart';

import '../test/test_helper.dart';
import 'test_fakes.dart';

// Mock-backed end-to-end coverage for email/password sign-in and the
// AuthWrapper routing matrix: the real widget tree, AuthService, auth/profile
// streams, and route selection run on device while the FirebaseAuth and
// GoogleSignIn plugin layers are faked (see google_sign_in_test.dart).

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

  Future<void> signInWithEmail(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'e2e@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password123',
    );
    await tester.pump();
    // The soft keyboard can cover the button on small viewports.
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
  }

  group('Email/password sign-in', () {
    testWidgets('routes to home when the profile is complete', (tester) async {
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

      await signInWithEmail(tester);

      expect(mockAuth.currentUser, isNotNull);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('routes to profile onboarding when no profile exists', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byType(LoginScreen), findsOneWidget);

      await signInWithEmail(tester);

      expect(mockAuth.currentUser, isNotNull);
      expect(find.byType(UserProfileScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('routes to profile onboarding when the profile is incomplete', (
      tester,
    ) async {
      // Username is set but names are empty, so isIncomplete is true and the
      // onboarding form prefills the username — proving this profile (not a
      // null one) reached AuthWrapper.
      fakeProfileService.emitProfile(
        const UserProfile(
          userId: 'test_user',
          username: 'e2e_user',
          firstName: '',
          lastName: '',
        ),
      );
      await pumpApp(tester);
      expect(find.byType(LoginScreen), findsOneWidget);

      await signInWithEmail(tester);

      expect(mockAuth.currentUser, isNotNull);
      expect(find.byType(UserProfileScreen), findsOneWidget);
      expect(find.text('Complete Your Profile'), findsOneWidget);
      expect(find.text('e2e_user'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
