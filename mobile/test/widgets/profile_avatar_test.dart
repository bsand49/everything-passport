import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/widgets/profile_avatar.dart';

void main() {
  group('ProfileAvatar', () {
    group('Initialization', () {
      testWidgets('shows fallback icon when no image is provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ProfileAvatar(fallbackIcon: Icons.person),
            ),
          ),
        );

        expect(find.byIcon(Icons.person), findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('shows edit button when onEditPressed is provided',
          (WidgetTester tester) async {
        bool editPressed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfileAvatar(
                onEditPressed: () => editPressed = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
        await tester.tap(find.byIcon(Icons.camera_alt));
        expect(editPressed, isTrue);
      });
    });
  });
}
