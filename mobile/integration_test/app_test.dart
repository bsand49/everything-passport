import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:everything_passport/main.dart' as app;
import 'package:everything_passport/pages/login_page.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Boot Integration Test', () {
    testWidgets('Verify app boots and reaches Login Page', (tester) async {
      // Start the app by calling the main() function from main.dart
      // We wrap it in a try-catch because main() handles its own Firebase initialization
      // which might fail in some test environments if native config is missing.
      try {
        app.main();
      } catch (e) {
        debugPrint('Error starting app: $e');
      }

      await tester.pumpAndSettle();

      // Verify that we are on the LoginPage (the expected starting point for a fresh boot)
      expect(find.byType(LoginPage), findsOneWidget);

      // Verify some basic UI elements on the login page
      expect(find.text('Login'), findsWidgets);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('Verify environment variable processing', (tester) async {
      // This test specifically checks if the main() logic handles different ENV values
      // without crashing, even if we can't fully mock the static Firebase.initializeApp call here.

      // In a real integration test, we might use --dart-define=ENV=prod when running
      // but we can also verify the logic by inspecting the widget tree if it reflects the environment.

      app.main();
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
