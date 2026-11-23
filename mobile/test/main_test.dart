import 'package:material_ui/material_ui.dart';
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
import 'package:everything_passport/widgets/email_verification_banner.dart';
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
      testWidgets('shows LoginScreen when user is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          createTestableWidget(child: const AuthWrapper(), user: null),
        );

        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets(
        'shows UserProfileScreen when user is logged in but profile is null',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestableWidget(
              child: const AuthWrapper(),
              user: FakeUser(),
              userProfile: null,
            ),
          );

          expect(find.byType(UserProfileScreen), findsOneWidget);
        },
      );

      testWidgets(
        'shows UserProfileScreen when user is logged in but profile is incomplete',
        (WidgetTester tester) async {
          final incompleteProfile = UserProfile(
            userId: 'test_uid',
            username: '', // incomplete
            firstName: 'Test',
            lastName: 'User',
          );

          await tester.pumpWidget(
            createTestableWidget(
              child: const AuthWrapper(),
              user: FakeUser(),
              userProfile: incompleteProfile,
            ),
          );

          expect(find.byType(UserProfileScreen), findsOneWidget);
        },
      );

      testWidgets(
        'shows HomeScreen when user is logged in and profile is complete',
        (WidgetTester tester) async {
          final completeProfile = const UserProfile(
            userId: 'test_uid',
            username: 'testuser',
            firstName: 'Test',
            lastName: 'User',
          );

          await tester.pumpWidget(
            createTestableWidget(
              child: const AuthWrapper(),
              user: FakeUser(),
              userProfile: completeProfile,
            ),
          );

          expect(find.byType(HomeScreen), findsOneWidget);
        },
      );

      testWidgets('shows verification banner for unverified password user', (
        WidgetTester tester,
      ) async {
        final completeProfile = const UserProfile(
          userId: 'test_uid',
          username: 'testuser',
          firstName: 'Test',
          lastName: 'User',
        );

        await tester.pumpWidget(
          createTestableWidget(
            child: const AuthWrapper(),
            user: FakeUser(
              emailVerified: false,
              providerData: [FakeUserInfo('password')],
            ),
            userProfile: completeProfile,
          ),
        );

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Verify your email address'), findsOneWidget);
      });

      testWidgets('hides verification banner for unverified Google user', (
        WidgetTester tester,
      ) async {
        final completeProfile = const UserProfile(
          userId: 'test_uid',
          username: 'testuser',
          firstName: 'Test',
          lastName: 'User',
        );

        await tester.pumpWidget(
          createTestableWidget(
            child: const AuthWrapper(),
            user: FakeUser(
              emailVerified: false,
              providerData: [FakeUserInfo('google.com')],
            ),
            userProfile: completeProfile,
          ),
        );

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('Verify your email address'), findsNothing);
      });
    });
  });

  group('MyApp', () {
    group('Initialization', () {
      testWidgets('renders MaterialApp with correct title and setup', (
        WidgetTester tester,
      ) async {
        final fakeAuth = FakeAuthService();
        final fakeUser = FakeUserProfileService();
        final fakeMeta = FakeMetadataService();

        await tester.pumpWidget(
          MyApp(
            authService: fakeAuth,
            userProfileService: fakeUser,
            metadataService: fakeMeta,
          ),
        );
        await tester.pump();

        expect(find.byType(MaterialApp), findsOneWidget);
        final MaterialApp app = tester.widget(find.byType(MaterialApp));
        expect(app.title, 'Everything Passport');
        expect(app.theme?.useMaterial3, true);
      });

      testWidgets('handles default providers and disposal', (
        WidgetTester tester,
      ) async {
        final fakeAuth = FakeAuthService();
        final fakeUser = FakeUserProfileService();

        // Emit a user to hit line 84 (switchMap branch for streamProfile)
        fakeAuth.emitUser(FakeUser());

        await tester.pumpWidget(
          MyApp(
            authService: fakeAuth,
            userProfileService: fakeUser,
            // Leave metadataService and httpClient null to hit lines 61, 73
          ),
        );
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

      testWidgets(
        'hides the verification banner after refresh emits a verified user',
        (WidgetTester tester) async {
          final fakeAuth = FakeAuthService();
          final fakeProfile = FakeUserProfileService();
          fakeProfile.emitProfile(
            const UserProfile(
              userId: 'test_user',
              username: 'testuser',
              firstName: 'Test',
              lastName: 'User',
            ),
          );
          fakeAuth.emitUser(
            FakeUser(
              emailVerified: false,
              providerData: [FakeUserInfo('password')],
            ),
          );
          // Simulate User.reload() publishing a fresh verified snapshot for
          // the same account through the auth stream.
          fakeAuth.reloadEmitsUser = FakeUser(
            emailVerified: true,
            providerData: [FakeUserInfo('password')],
          );

          await tester.pumpWidget(
            MyApp(
              authService: fakeAuth,
              userProfileService: fakeProfile,
              metadataService: FakeMetadataService(),
            ),
          );
          await tester.pump();

          expect(find.text('Verify your email address'), findsOneWidget);

          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();

          expect(fakeAuth.reloadCurrentUserCalls, 1);
          expect(find.byType(HomeScreen), findsOneWidget);
          expect(find.byType(EmailVerificationBanner), findsNothing);
          // The banner slot must collapse entirely: the host Column's first
          // child is a zero-height SizedBox, not the SafeArea that reserves
          // the status-bar inset while the banner is visible.
          final hostColumn = tester.widget<Column>(
            find
                .ancestor(
                  of: find.byType(HomeScreen),
                  matching: find.byType(Column),
                )
                .first,
          );
          expect(hostColumn.children.length, 2);
          expect(hostColumn.children.first, isA<SizedBox>());
          expect(hostColumn.children.last, isA<Expanded>());
        },
      );

      testWidgets(
        'does not restart the profile stream for same-uid user snapshots',
        (WidgetTester tester) async {
          final fakeAuth = FakeAuthService();
          final fakeProfile = FakeUserProfileService();

          await tester.pumpWidget(
            MyApp(
              authService: fakeAuth,
              userProfileService: fakeProfile,
              metadataService: FakeMetadataService(),
            ),
          );
          await tester.pump();

          fakeAuth.emitUser(FakeUser());
          await tester.pump();
          expect(fakeProfile.streamProfileCalls, 1);

          // A reload-style snapshot for the same uid must not resubscribe.
          fakeAuth.emitUser(FakeUser(emailVerified: false));
          await tester.pump();
          expect(fakeProfile.streamProfileCalls, 1);

          // A genuinely different user does resubscribe.
          fakeAuth.emitUser(FakeUser(uid: 'other_user'));
          await tester.pump();
          expect(fakeProfile.streamProfileCalls, 2);
        },
      );
    });
  });
}
