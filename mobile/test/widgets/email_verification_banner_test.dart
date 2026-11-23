import 'package:firebase_auth/firebase_auth.dart';
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
      var fakeNow = DateTime(2025);
      final authService = FakeAuthService()..now = () => fakeNow;
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
      fakeNow = fakeNow.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('resend is disabled with a countdown during cooldown', (
      WidgetTester tester,
    ) async {
      var fakeNow = DateTime(2025);
      final authService = FakeAuthService()..now = () => fakeNow;
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

      fakeNow = fakeNow.add(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('resend re-enables after the cooldown elapses', (
      WidgetTester tester,
    ) async {
      var fakeNow = DateTime(2025);
      final authService = FakeAuthService()..now = () => fakeNow;
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

      fakeNow = fakeNow.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
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

    testWidgets('cooldown is shared across banner instances', (
      WidgetTester tester,
    ) async {
      var fakeNow = DateTime(2025);
      final authService = FakeAuthService()..now = () => fakeNow;
      final user = FakeUser(
        emailVerified: false,
        providerData: [FakeUserInfo('password')],
      );

      // Send from the first banner instance.
      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: EmailVerificationBanner(
              resendCooldown: const Duration(seconds: 3),
            ),
          ),
          authService: authService,
          user: user,
        ),
      );
      await tester.tap(find.text('Resend'));
      await tester.pump();
      expect(authService.sendEmailVerificationCalls, 1);

      // A second, freshly mounted banner (e.g. Settings after Home) must
      // honour the same deadline rather than restarting Resend. The
      // different key forces a new State so the element is not reused.
      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: EmailVerificationBanner(
              key: const ValueKey('second-banner'),
              resendCooldown: const Duration(seconds: 3),
            ),
          ),
          authService: authService,
          user: user,
        ),
      );
      await tester.pump();

      expect(find.text('Resend (3s)'), findsOneWidget);
      await tester.tap(find.text('Resend (3s)'));
      await tester.pump();
      expect(authService.sendEmailVerificationCalls, 1);

      fakeNow = fakeNow.add(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('mounted banner starts cooldown when another sends', (
      WidgetTester tester,
    ) async {
      var fakeNow = DateTime(2025);
      final authService = FakeAuthService()..now = () => fakeNow;
      final user = FakeUser(
        emailVerified: false,
        providerData: [FakeUserInfo('password')],
      );
      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: EmailVerificationBanner(
              resendCooldown: const Duration(seconds: 3),
            ),
          ),
          authService: authService,
          user: user,
        ),
      );
      await tester.pump();
      expect(find.text('Resend'), findsOneWidget);

      // A send recorded elsewhere (e.g. the Settings banner) must reach
      // this still-mounted banner without a remount.
      await authService.sendEmailVerification();
      await tester.pump();

      expect(find.text('Resend (3s)'), findsOneWidget);
      await tester.tap(find.text('Resend (3s)'));
      await tester.pump();
      expect(authService.sendEmailVerificationCalls, 1);

      fakeNow = fakeNow.add(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('cooldown does not leak across accounts', (
      WidgetTester tester,
    ) async {
      var fakeNow = DateTime(2025);
      final authService = FakeAuthService()..now = () => fakeNow;
      final userA = FakeUser(
        uid: 'user_a',
        emailVerified: false,
        providerData: [FakeUserInfo('password')],
      );
      final userB = FakeUser(
        uid: 'user_b',
        emailVerified: false,
        providerData: [FakeUserInfo('password')],
      );

      Widget bannerFor(User user) => createTestableWidget(
        child: Scaffold(
          body: EmailVerificationBanner(
            resendCooldown: const Duration(seconds: 3),
          ),
        ),
        authService: authService,
        user: user,
      );

      // Account A sends a verification email.
      await tester.pumpWidget(bannerFor(userA));
      await tester.tap(find.text('Resend'));
      await tester.pump();
      expect(find.text('Resend (3s)'), findsOneWidget);

      // Signing in as account B must not inherit A's cooldown.
      await tester.pumpWidget(bannerFor(userB));
      await tester.pump();
      expect(find.text('Resend'), findsOneWidget);

      fakeNow = fakeNow.add(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('cooldown reflects elapsed wall-clock time', (
      WidgetTester tester,
    ) async {
      var fakeNow = DateTime(2025);
      final authService = FakeAuthService();
      authService.now = () => fakeNow;
      final user = FakeUser(
        emailVerified: false,
        providerData: [FakeUserInfo('password')],
      );
      authService.verificationEmailSentAtByUid[user.uid] = DateTime(2025)
          .subtract(const Duration(seconds: 59));
      await tester.pumpWidget(
        createTestableWidget(
          child: Scaffold(
            body: EmailVerificationBanner(
              resendCooldown: const Duration(seconds: 60),
            ),
          ),
          authService: authService,
          user: user,
        ),
      );
      await tester.pump();

      // Only ~1s of the 60s cooldown remains.
      expect(find.text('Resend (1s)'), findsOneWidget);

      // Jump the clock past the deadline — expiry does not depend on
      // receiving every intermediate timer tick.
      fakeNow = fakeNow.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Resend'), findsOneWidget);
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
