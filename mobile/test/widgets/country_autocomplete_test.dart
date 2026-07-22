import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

        // Need to tap the option in the list, not the text in the field
        await tester.tap(find.widgetWithText(InkWell, 'France'));
        await tester.pumpAndSettle();

        expect(selectedCountry?.id, 'FR');
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
    });
  });
}
