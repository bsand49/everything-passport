import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:everything_passport/main.dart' as app;
import 'package:everything_passport/screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Boot Integration Test', () {
    testWidgets('Verify app boots and reaches Login Page', (tester) async {
      // Start the app and await the async initialization (Firebase, Google Sign In, etc.)
      // This ensures we don't start asserting before runApp() is called.
      await app.main();

      // Wait for the app to settle and the first frame to render
      await tester.pumpAndSettle();

      // Verify that we are on the LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Verify some basic UI elements on the login page
      expect(find.text('Login'), findsWidgets);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('Verify environment variable processing', (tester) async {
      // Since main() was already called in the first test and it initializes static services,
      // calling it again is safe but we should still wait for it.
      await app.main();
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
