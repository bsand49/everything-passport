import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/widgets/email_verification_banner.dart';

import '../test_helper.dart';

void main() {
  group('EmailVerificationBanner', () {
    testWidgets('is hidden when there is no user', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const Scaffold(body: EmailVerificationBanner()),
        ),
      );

      expect(find.text('Verify your email address'), findsNothing);
    });

    testWidgets('is hidden for a verified password user', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const Scaffold(body: EmailVerificationBanner()),
          user: FakeUser(providerData: [FakeUserInfo('password')]),
        ),
      );

      expect(find.text('Verify your email address'), findsNothing);
    });

    testWidgets('is hidden for an unverified Google user', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const Scaffold(body: EmailVerificationBanner()),
          user: FakeUser(
            emailVerified: false,
            providerData: [FakeUserInfo('google.com')],
          ),
        ),
      );

      expect(find.text('Verify your email address'), findsNothing);
    });

    testWidgets('is visible for an unverified password user', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const Scaffold(body: EmailVerificationBanner()),
          user: FakeUser(
            emailVerified: false,
            providerData: [FakeUserInfo('password')],
          ),
        ),
      );

      expect(find.text('Verify your email address'), findsOneWidget);
      expect(find.text('Resend'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('resend sends a verification email and shows a SnackBar', (
      WidgetTester tester,
    ) async {
      final authService = FakeAuthService();
      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: EmailVerificationBanner(
              resendCooldown: const Duration(seconds: 1),
            ),
          ),
          authService: authService,
          user: FakeUser(
            emailVerified: false,
            providerData: [FakeUserInfo('password')],
          ),
        ),
      );

      await tester.tap(find.text('Resend'));
      await tester.pump();

      expect(authService.sendEmailVerificationCalls, 1);
      expect(
        find.text('Verification email sent. Check your inbox.'),
        findsOneWidget,
      );

      // Let the cooldown elapse so no timer is pending at test end.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('resend is disabled with a countdown during cooldown', (
      WidgetTester tester,
    ) async {
      final authService = FakeAuthService();
      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: EmailVerificationBanner(
              resendCooldown: const Duration(seconds: 3),
            ),
          ),
          authService: authService,
          user: FakeUser(
            emailVerified: false,
            providerData: [FakeUserInfo('password')],
          ),
        ),
      );

      await tester.tap(find.text('Resend'));
      await tester.pump();

      expect(find.text('Resend (3s)'), findsOneWidget);

      // Tapping the disabled button must not send again.
      await tester.tap(find.text('Resend (3s)'));
      await tester.pump();
      expect(authService.sendEmailVerificationCalls, 1);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('resend re-enables after the cooldown elapses', (
      WidgetTester tester,
    ) async {
      final authService = FakeAuthService();
      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: EmailVerificationBanner(
              resendCooldown: const Duration(seconds: 2),
            ),
          ),
          authService: authService,
          user: FakeUser(
            emailVerified: false,
            providerData: [FakeUserInfo('password')],
          ),
        ),
      );

      await tester.tap(find.text('Resend'));
      await tester.pump();
      expect(find.text('Resend (2s)'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.text('Resend'), findsOneWidget);
    });

    testWidgets('resend shows an error SnackBar on failure', (
      WidgetTester tester,
    ) async {
      final authService = FakeAuthService()..throwError = true;
      await tester.pumpWidget(
        createTestableWidget(
          child: const Scaffold(body: EmailVerificationBanner()),
          authService: authService,
          user: FakeUser(
            emailVerified: false,
            providerData: [FakeUserInfo('password')],
          ),
        ),
      );

      await tester.tap(find.text('Resend'));
      await tester.pump();

      expect(authService.sendEmailVerificationCalls, 1);
      expect(
        find.textContaining('Could not send verification email'),
        findsOneWidget,
      );

      // A failed send must not start the cooldown — the user can retry.
      expect(find.text('Resend'), findsOneWidget);
      await tester.tap(find.text('Resend'));
      await tester.pump();
      expect(authService.sendEmailVerificationCalls, 2);
    });

    testWidgets('refresh reloads the current user', (
      WidgetTester tester,
    ) async {
      final authService = FakeAuthService();
      final user = FakeUser(
        emailVerified: false,
        providerData: [FakeUserInfo('password')],
      );
      await tester.pumpWidget(
        createTestableWidget(
          child: const Scaffold(body: EmailVerificationBanner()),
          authService: authService,
          user: user,
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));
      // Simulate reload() updating the user after verifying elsewhere.
      user.emailVerified = true;
      await tester.pump();

      expect(authService.reloadCurrentUserCalls, 1);
      expect(find.text('Verify your email address'), findsNothing);
    });

    testWidgets('refresh shows an error SnackBar on failure', (
      WidgetTester tester,
    ) async {
      final authService = FakeAuthService()..throwError = true;
      await tester.pumpWidget(
        createTestableWidget(
          child: const Scaffold(body: EmailVerificationBanner()),
          authService: authService,
          user: FakeUser(
            emailVerified: false,
            providerData: [FakeUserInfo('password')],
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(authService.reloadCurrentUserCalls, 1);
      expect(
        find.textContaining('Could not refresh verification status'),
        findsOneWidget,
      );
    });
  });

  group('EmailVerificationBannerHost', () {
    testWidgets('returns the child directly when verification is not needed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: EmailVerificationBannerHost(
              child: const Text('Child content'),
            ),
          ),
          user: FakeUser(),
        ),
      );

      expect(find.text('Child content'), findsOneWidget);
      expect(find.text('Verify your email address'), findsNothing);
    });

    testWidgets('shows the banner above the child when needed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: EmailVerificationBannerHost(
              child: const Text('Child content'),
            ),
          ),
          user: FakeUser(
            emailVerified: false,
            providerData: [FakeUserInfo('password')],
          ),
        ),
      );

      expect(find.text('Verify your email address'), findsOneWidget);
      expect(find.text('Child content'), findsOneWidget);
    });
  });
}
