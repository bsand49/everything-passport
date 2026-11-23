import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:everything_passport/main.dart' as app;
import 'package:everything_passport/screens/login_screen.dart';
import 'package:everything_passport/screens/signup_screen.dart';
import 'package:everything_passport/services/auth_service.dart';
import 'package:everything_passport/utils/validators.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> ensureLoggedOut(WidgetTester tester) async {
    await tester.pumpAndSettle();
    if (find.byType(LoginScreen).evaluate().isEmpty) {
      final Finder appFinder = find.byElementPredicate(
        (element) => element.widget is MaterialApp,
      );
      if (appFinder.evaluate().isNotEmpty) {
        final context = tester.element(appFinder);
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
        await tester.pumpAndSettle();
      }
    }
  }

  group('App Integration Tests', () {
    group('Initialization', () {
      testWidgets('Verify app boots and reaches Login Page', (tester) async {
        await app.main();
        await ensureLoggedOut(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Login'), findsWidgets);
        expect(find.text('Sign in with Google'), findsOneWidget);
      });
    });

    group('Validation', () {
      testWidgets('Verify login form validation', (tester) async {
        await app.main();
        await ensureLoggedOut(tester);

        // Attempt to login with empty fields
        final loginButton = find.widgetWithText(ElevatedButton, 'Login');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Verify validation messages (consistent with Validators utility)
        expect(find.text(Validators.validateEmail(null)!), findsOneWidget);
        expect(
          find.text(
            Validators.validateRequired(
              null,
              message: 'Please enter your password',
            )!,
          ),
          findsOneWidget,
        );
      });
    });

    group('Navigation', () {
      testWidgets('Verify navigation between Login and Sign Up', (
        tester,
      ) async {
        await app.main();
        await ensureLoggedOut(tester);

        // Navigate to Sign Up
        final signUpLink = find.text('Don\'t have an account? Sign Up');
        await tester.tap(signUpLink);
        await tester.pumpAndSettle();

        expect(find.byType(SignUpScreen), findsOneWidget);
        expect(find.text('Sign Up'), findsWidgets);

        // Go back to Login
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
        } else {
          await tester.pageBack();
        }
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Google Sign-In', () {
      testWidgets('tap reaches a defined outcome without crashing', (
        tester,
      ) async {
        await app.main();
        await ensureLoggedOut(tester);

        await tester.tap(find.text('Sign in with Google'));

        // The OAuth flow either opens the native account picker (the button
        // stays in its loading state) or surfaces an error SnackBar — e.g. an
        // invalid SERVER_CLIENT_ID. Any other silent outcome is a regression.
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        final flowInitiated = find
            .byType(CircularProgressIndicator)
            .evaluate()
            .isNotEmpty;
        final errorShown = find.byType(SnackBar).evaluate().isNotEmpty;

        expect(flowInitiated || errorShown, isTrue);
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });
  });
}
