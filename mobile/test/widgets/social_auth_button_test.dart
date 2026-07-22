import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/widgets/social_auth_button.dart';

void main() {
  group('SocialAuthButton', () {
    group('Initialization', () {
      testWidgets('renders label and icon', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialAuthButton(
                onPressed: () {},
                label: 'Google',
                icon: const Icon(Icons.login),
              ),
            ),
          ),
        );

        expect(find.text('Google'), findsOneWidget);
        expect(find.byIcon(Icons.login), findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('shows spinner when loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialAuthButton(
                onPressed: () {},
                label: 'Google',
                icon: const Icon(Icons.login),
                isLoading: true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.login), findsNothing);
      });
    });
  });
}
