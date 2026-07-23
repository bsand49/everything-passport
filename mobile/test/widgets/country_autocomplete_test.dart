import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:country_flags/country_flags.dart';
import 'package:everything_passport/widgets/country_autocomplete.dart';
import 'package:everything_passport/models/country.dart';

void main() {
  final countries = [
    Country(
        id: 'GB', name: 'United Kingdom', searchKeywords: ['uk', 'britain']),
    Country(id: 'US', name: 'United States', searchKeywords: ['usa']),
    Country(id: 'FR', name: 'France', searchKeywords: ['fr']),
  ];

  group('CountryAutocomplete', () {
    group('Initialization', () {
      testWidgets('displays initialValue name', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountryAutocomplete(
                countries: countries,
                initialValue: countries.first,
                onSelected: (v) {},
              ),
            ),
          ),
        );

        expect(find.text('United Kingdom'), findsOneWidget);
      });

      testWidgets('displays initialValue flag', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountryAutocomplete(
                countries: countries,
                initialValue: countries.first, // United Kingdom
                onSelected: (v) {},
              ),
            ),
          ),
        );

        expect(
            find.descendant(
              of: find.byType(TextFormField),
              matching: find.byType(CountryFlag),
            ),
            findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('filters options based on input',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountryAutocomplete(
                countries: countries,
                onSelected: (v) {},
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'Uni');
        await tester.pumpAndSettle();

        expect(find.text('United Kingdom'), findsOneWidget);
        expect(find.text('United States'), findsOneWidget);
        expect(find.text('France'), findsNothing);
      });

      testWidgets('shows flags in options list', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountryAutocomplete(
                countries: countries,
                onSelected: (v) {},
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), '');
        await tester.pumpAndSettle();

        // Should see 3 CountryFlag widgets in the options list (one for each country)
        expect(find.byType(CountryFlag), findsNWidgets(3));
      });

      testWidgets('calls onSelected when an option is picked',
          (WidgetTester tester) async {
        Country? selectedCountry;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountryAutocomplete(
                countries: countries,
                onSelected: (v) => selectedCountry = v,
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'France');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(InkWell, 'France'));
        await tester.pumpAndSettle();

        expect(selectedCountry?.id, 'FR');
      });

      testWidgets('updates prefix icon to flag when an option is picked',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountryAutocomplete(
                countries: countries,
                onSelected: (v) {},
              ),
            ),
          ),
        );

        // Before selection, should show the default prefix icon (Icons.flag)
        expect(find.byIcon(Icons.flag), findsOneWidget);
        expect(
            find.descendant(
              of: find.byType(TextFormField),
              matching: find.byType(CountryFlag),
            ),
            findsNothing);

        await tester.enterText(find.byType(TextFormField), 'France');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(InkWell, 'France'));
        await tester.pumpAndSettle();

        // After selection, TextFormField should have CountryFlag as prefix
        expect(
            find.descendant(
              of: find.byType(TextFormField),
              matching: find.byType(CountryFlag),
            ),
            findsOneWidget);
        expect(find.byIcon(Icons.flag), findsNothing);
      });

      testWidgets('updates prefix icon to flag when valid name is typed',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountryAutocomplete(
                countries: countries,
                onSelected: (v) {},
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'United States');
        await tester.pumpAndSettle();

        // Typing exactly a country name should show the flag in the field
        expect(
            find.descendant(
              of: find.byType(TextFormField),
              matching: find.byType(CountryFlag),
            ),
            findsOneWidget);
      });

      testWidgets('clears selection when clear icon is pressed',
          (WidgetTester tester) async {
        Country? selectedCountry = countries.first;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: CountryAutocomplete(
                    countries: countries,
                    initialValue: selectedCountry,
                    onSelected: (v) => setState(() => selectedCountry = v),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(selectedCountry, isNull);
      });

      testWidgets('reverts to default icon when field is cleared',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountryAutocomplete(
                countries: countries,
                initialValue: countries.last, // France
                onSelected: (v) {},
              ),
            ),
          ),
        );

        // Should start with France's flag
        expect(
            find.descendant(
              of: find.byType(TextFormField),
              matching: find.byType(CountryFlag),
            ),
            findsOneWidget);

        // Tap the clear icon
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // Should revert to default flag icon
        expect(find.byIcon(Icons.flag), findsOneWidget);
        expect(
            find.descendant(
              of: find.byType(TextFormField),
              matching: find.byType(CountryFlag),
            ),
            findsNothing);
      });
    });
  });
}
