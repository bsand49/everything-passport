import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:everything_passport/main.dart';
import 'package:everything_passport/screens/login_screen.dart';
import 'package:everything_passport/screens/home_screen.dart';
import 'package:everything_passport/screens/user_profile_screen.dart';
import 'package:everything_passport/models/user_profile.dart';
import 'package:everything_passport/services/metadata_service.dart';
import 'package:http/http.dart' as http;
import 'test_helper.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'testing',
        appId: 'testing',
        messagingSenderId: 'testing',
        projectId: 'testing',
        storageBucket: 'everything-passport-dev.firebasestorage.app',
      ),
    );
  } catch (e) {
    debugPrint('Firebase already initialized or error: $e');
  }

  group('AuthWrapper', () {
    group('Initialization', () {
      testWidgets('shows LoginScreen when user is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const AuthWrapper(),
          user: null,
        ));

        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets(
          'shows UserProfileScreen when user is logged in but profile is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(
          child: const AuthWrapper(),
          user: FakeUser(),
          userProfile: null,
        ));

        expect(find.byType(UserProfileScreen), findsOneWidget);
      });

      testWidgets(
          'shows UserProfileScreen when user is logged in but profile is incomplete',
          (WidgetTester tester) async {
        final incompleteProfile = UserProfile(
          userId: 'test_uid',
          username: '', // incomplete
          firstName: 'Test',
          lastName: 'User',
        );

        await tester.pumpWidget(createTestableWidget(
          child: const AuthWrapper(),
          user: FakeUser(),
          userProfile: incompleteProfile,
        ));

        expect(find.byType(UserProfileScreen), findsOneWidget);
      });

      testWidgets(
          'shows HomeScreen when user is logged in and profile is complete',
          (WidgetTester tester) async {
        final completeProfile = const UserProfile(
          userId: 'test_uid',
          username: 'testuser',
          firstName: 'Test',
          lastName: 'User',
        );

        await tester.pumpWidget(createTestableWidget(
          child: const AuthWrapper(),
          user: FakeUser(),
          userProfile: completeProfile,
        ));

        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });
  });

  group('MyApp', () {
    group('Initialization', () {
      testWidgets('renders MaterialApp with correct title and setup',
          (WidgetTester tester) async {
        final fakeAuth = FakeAuthService();
        final fakeUser = FakeUserProfileService();
        final fakeMeta = FakeMetadataService();

        await tester.pumpWidget(MyApp(
          authService: fakeAuth,
          userProfileService: fakeUser,
          metadataService: fakeMeta,
        ));
        await tester.pump();

        expect(find.byType(MaterialApp), findsOneWidget);
        final MaterialApp app = tester.widget(find.byType(MaterialApp));
        expect(app.title, 'Everything Passport');
        expect(app.theme?.useMaterial3, true);
      });

      testWidgets('handles default providers and disposal',
          (WidgetTester tester) async {
        final fakeAuth = FakeAuthService();
        final fakeUser = FakeUserProfileService();

        // Emit a user to hit line 84 (switchMap branch for streamProfile)
        fakeAuth.emitUser(FakeUser());

        await tester.pumpWidget(MyApp(
          authService: fakeAuth,
          userProfileService: fakeUser,
          // Leave metadataService and httpClient null to hit lines 61, 73
        ));
        await tester.pump(); // Allow streams to propagate

        // Verify that providers are available
        final BuildContext context = tester.element(find.byType(AuthWrapper));
        expect(Provider.of<http.Client>(context, listen: false), isNotNull);
        expect(Provider.of<MetadataService>(context, listen: false), isNotNull);

        // Verify that the user was propagated through the StreamProvider
        expect(Provider.of<User?>(context, listen: false), isNotNull);

        // Unmount the widget to hit the dispose logic in lines 62-64
        await tester.pumpWidget(Container());
      });
    });
  });
}
