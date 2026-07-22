import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/widgets/auth_text_field.dart';

void main() {
  group('AuthTextField', () {
    group('Initialization', () {
      testWidgets('renders label and prefix icon', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuthTextField(
                labelText: 'Username',
                prefixIcon: Icons.person,
              ),
            ),
          ),
        );

        expect(find.text('Username'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('updates controller when text is entered',
          (WidgetTester tester) async {
        final controller = TextEditingController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuthTextField(
                labelText: 'Email',
                controller: controller,
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'test@example.com');
        expect(controller.text, 'test@example.com');
      });

      testWidgets('toggles password visibility', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AuthTextField(
                labelText: 'Password',
                obscureText: true,
              ),
            ),
          ),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.obscureText, isTrue);

        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();

        final updatedTextField =
            tester.widget<TextField>(find.byType(TextField));
        expect(updatedTextField.obscureText, isFalse);
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });
    });

    group('Validation', () {
      testWidgets('displays validation error', (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: AuthTextField(
                  labelText: 'Required Field',
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Error Message' : null,
                ),
              ),
            ),
          ),
        );

        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text('Error Message'), findsOneWidget);
      });
    });
  });
}
