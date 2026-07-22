import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/widgets/loading_button.dart';

void main() {
  group('LoadingButton', () {
    group('Initialization', () {
      testWidgets('renders child when not loading',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoadingButton(
                onPressed: () {},
                child: const Text('Submit'),
              ),
            ),
          ),
        );

        expect(find.text('Submit'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Interactions', () {
      testWidgets('renders spinner and disables button when loading',
          (WidgetTester tester) async {
        bool pressed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoadingButton(
                onPressed: () => pressed = true,
                isLoading: true,
                child: const Text('Submit'),
              ),
            ),
          ),
        );

        expect(find.text('Submit'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.byType(ElevatedButton));
        expect(pressed, isFalse);
      });

      testWidgets('calls onPressed when clicked', (WidgetTester tester) async {
        bool pressed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoadingButton(
                onPressed: () => pressed = true,
                child: const Text('Click Me'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(pressed, isTrue);
      });
    });
  });
}
