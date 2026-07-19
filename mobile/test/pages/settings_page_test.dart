import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/pages/settings_page.dart';
import 'package:everything_passport/pages/user_profile_page.dart';
import 'package:everything_passport/models/user_profile.dart';
import 'package:everything_passport/services/auth_service.dart';
import '../test_helper.dart';

import 'settings_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthService>(),
  MockSpec<NavigatorObserver>(),
])
void main() {
  group('SettingsPage Tests', () {
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
        uid: 'test_uid',
        username: 'traveler_john',
        firstName: 'John',
        lastName: 'Doe',
      );
      mockObserver = MockNavigatorObserver();
    });

    /// Helper to reduce redundant pumpWidget boilerplate
    /// Pushes SettingsPage onto a parent route so that popping works realistically
    Future<void> pumpSettingsPage(WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
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

      // Navigate to SettingsPage
      await tester.tap(find.text('Go to Settings'));
      await tester.pumpAndSettle();
    }

    testWidgets('displays header and options correctly', (WidgetTester tester) async {
      await pumpSettingsPage(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Change your name, photo, and details'), findsOneWidget);
      expect(find.text('App Version 1.0.0'), findsOneWidget);
    });

    testWidgets('navigates to UserProfilePage on Edit Profile tap',
        (WidgetTester tester) async {
      await pumpSettingsPage(tester);

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(UserProfilePage), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog and handles successful sign out',
        (WidgetTester tester) async {
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      await pumpSettingsPage(tester);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Ensure confirmation dialog is displayed
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Logout'));
      await tester.pumpAndSettle();

      // Verify page was popped, dialog dismissed, and signOut called
      verify(mockObserver.didPop(any, any)).called(greaterThan(0));
      verify(mockAuthService.signOut()).called(1);
    });

    testWidgets('shows logout dialog and dismisses on Cancel tap',
        (WidgetTester tester) async {
      await pumpSettingsPage(tester);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Assert no sign out was made, and the dialog is dismissed
      verifyNever(mockAuthService.signOut());
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows SnackBar error message when signOut throws an exception',
        (WidgetTester tester) async {
      when(mockAuthService.signOut()).thenThrow(Exception('Network error'));

      await pumpSettingsPage(tester);

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
}
