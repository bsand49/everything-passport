import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/widgets/date_picker_field.dart';
import 'package:intl/intl.dart';

void main() {
  group('DatePickerField', () {
    group('Initialization', () {
      testWidgets('displays label and formatted date',
          (WidgetTester tester) async {
        final date = DateTime(2020, 5, 15);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DatePickerField(
                labelText: 'Birth Date',
                value: date,
                onChanged: (v) {},
                firstDate: DateTime(2000),
                lastDate: DateTime(2030),
              ),
            ),
          ),
        );

        expect(find.text('Birth Date'), findsOneWidget);
        expect(find.text(DateFormat.yMd().format(date)), findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('opens picker on tap', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DatePickerField(
                labelText: 'Birth Date',
                value: null,
                onChanged: (v) {},
                firstDate: DateTime(2000),
                lastDate: DateTime(2030),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(DatePickerField));
        await tester.pumpAndSettle();

        expect(find.byType(CalendarDatePicker), findsOneWidget);
      });

      testWidgets('clears date when clear icon is pressed',
          (WidgetTester tester) async {
        DateTime? selectedDate = DateTime(2020, 5, 15);
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: DatePickerField(
                    labelText: 'Birth Date',
                    value: selectedDate,
                    onChanged: (date) => setState(() => selectedDate = date),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();

        expect(selectedDate, isNull);
      });
    });
  });
}
