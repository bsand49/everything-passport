import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/screens/settings_screen.dart';
import 'package:everything_passport/screens/user_profile_screen.dart';
import 'package:everything_passport/models/user_profile.dart';
import 'package:everything_passport/services/auth_service.dart';
import '../test_helper.dart';

import 'settings_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthService>(),
  MockSpec<NavigatorObserver>(),
])
void main() {
  group('SettingsScreen', () {
    late MockAuthService mockAuthService;
    late UserProfile mockProfile;
    late MockNavigatorObserver mockObserver;

    setUpAll(() {
      provideDummy<Route<dynamic>>(
          MaterialPageRoute(builder: (_) => const SizedBox()));
    });

    setUp(() {
      mockAuthService = MockAuthService();
      mockProfile = UserProfile(
        userId: 'test_user',
        username: 'traveler_john',
        firstName: 'John',
        lastName: 'Doe',
      );
      mockObserver = MockNavigatorObserver();
    });

    /// Helper to reduce redundant pumpWidget boilerplate
    /// Pushes SettingsScreen onto a parent route so that popping works realistically
    Future<void> pumpSettingsScreen(WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
                child: const Text('Go to Settings'),
              );
            },
          ),
        ),
        authService: mockAuthService,
        userProfile: mockProfile,
        observer: mockObserver,
      ));

      // Navigate to SettingsScreen
      await tester.tap(find.text('Go to Settings'));
      await tester.pumpAndSettle();
    }

    group('Initialization', () {
      testWidgets('displays header, options, and icons correctly',
          (WidgetTester tester) async {
        await pumpSettingsScreen(tester);

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.text('Logout'), findsOneWidget);
        expect(
            find.text('Change your name, photo, and details'), findsOneWidget);
        expect(find.text('App Version 1.0.0'), findsOneWidget);

        expect(find.byIcon(Icons.person_outline), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });
    });

    group('Interactions', () {
      group('Logout', () {
        testWidgets(
            'shows logout confirmation dialog and handles successful sign out',
            (WidgetTester tester) async {
          when(mockAuthService.signOut()).thenAnswer((_) async {});

          await pumpSettingsScreen(tester);

          await tester.tap(find.text('Logout'));
          await tester.pumpAndSettle();

          // Ensure confirmation dialog is displayed
          expect(
              find.text('Are you sure you want to log out?'), findsOneWidget);

          await tester.tap(find.widgetWithText(TextButton, 'Logout'));
          await tester.pumpAndSettle();

          // Verify page was popped, dialog dismissed, and signOut called
          verify(mockObserver.didPop(any, any)).called(greaterThan(0));
          verify(mockAuthService.signOut()).called(1);
        });

        testWidgets('shows logout dialog and dismisses on Cancel tap',
            (WidgetTester tester) async {
          await pumpSettingsScreen(tester);

          await tester.tap(find.text('Logout'));
          await tester.pumpAndSettle();

          expect(
              find.text('Are you sure you want to log out?'), findsOneWidget);

          await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
          await tester.pumpAndSettle();

          // Assert no sign out was made, and the dialog is dismissed
          verifyNever(mockAuthService.signOut());
          expect(find.byType(AlertDialog), findsNothing);
        });

        testWidgets(
            'shows SnackBar error message when signOut throws an exception',
            (WidgetTester tester) async {
          when(mockAuthService.signOut()).thenThrow(Exception('Network error'));

          await pumpSettingsScreen(tester);

          // Trigger the logout flow
          await tester.tap(find.text('Logout'));
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(TextButton, 'Logout'));
          await tester.pumpAndSettle();

          // Expect a SnackBar containing the error description
          expect(find.byType(SnackBar), findsOneWidget);
          expect(
            find.text('Error signing out: Exception: Network error'),
            findsOneWidget,
          );
        });
      });
    });

    group('Navigation', () {
      testWidgets('navigates to UserProfileScreen on Edit Profile tap',
          (WidgetTester tester) async {
        await pumpSettingsScreen(tester);

        await tester.tap(find.text('Edit Profile'));
        await tester.pumpAndSettle();

        expect(find.byType(UserProfileScreen), findsOneWidget);

        // Verify navigation occurred using observer
        verify(mockObserver.didPush(any, any)).called(greaterThan(1));
      });

      testWidgets('navigates back on back button tap',
          (WidgetTester tester) async {
        await pumpSettingsScreen(tester);

        // Tap the back button in the AppBar
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Verify the screen was popped
        verify(mockObserver.didPop(any, any)).called(1);
        expect(find.byType(SettingsScreen), findsNothing);
      });
    });
  });
}
