import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/widgets/date_picker_field.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Widget buildTestApp({Locale? locale, required Widget child}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('en', 'GB'), Locale('en', 'US')],
    home: Scaffold(body: child),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('DatePickerField', () {
    group('Initialization', () {
      testWidgets('displays label and formatted date', (
        WidgetTester tester,
      ) async {
        final date = DateTime(2020, 5, 15);
        await tester.pumpWidget(
          buildTestApp(
            child: DatePickerField(
              labelText: 'Birth Date',
              value: date,
              onChanged: (v) {},
              firstDate: DateTime(2000),
              lastDate: DateTime(2030),
            ),
          ),
        );

        expect(find.text('Birth Date'), findsOneWidget);
        expect(find.text(DateFormat.yMd().format(date)), findsOneWidget);
      });

      testWidgets('formats the date for en_GB and en_US locales', (
        WidgetTester tester,
      ) async {
        final date = DateTime(2023, 10, 27);
        final cases = [
          (const Locale('en', 'GB'), '27/10/2023'),
          (const Locale('en', 'US'), '10/27/2023'),
        ];

        for (final (locale, expected) in cases) {
          await tester.pumpWidget(
            buildTestApp(
              locale: locale,
              child: Builder(
                builder: (context) => DatePickerField(
                  labelText: 'Birth Date',
                  value: date,
                  onChanged: (v) {},
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2030),
                  locale: Localizations.localeOf(context),
                ),
              ),
            ),
          );

          expect(find.text(expected), findsOneWidget);
        }
      });
    });

    group('Interactions', () {
      testWidgets('opens picker on tap', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            child: DatePickerField(
              labelText: 'Birth Date',
              value: null,
              onChanged: (v) {},
              firstDate: DateTime(2000),
              lastDate: DateTime(2030),
            ),
          ),
        );

        await tester.tap(find.byType(DatePickerField));
        await tester.pumpAndSettle();

        expect(find.byType(CalendarDatePicker), findsOneWidget);
      });

      testWidgets('clears date when clear icon is pressed', (
        WidgetTester tester,
      ) async {
        DateTime? selectedDate = DateTime(2020, 5, 15);
        await tester.pumpWidget(
          buildTestApp(
            child: StatefulBuilder(
              builder: (context, setState) {
                return DatePickerField(
                  labelText: 'Birth Date',
                  value: selectedDate,
                  onChanged: (date) => setState(() => selectedDate = date),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2030),
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
