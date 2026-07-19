import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/models/country.dart';

void main() {
  group('Country Model Tests', () {
    test('Constructor creates Country object', () {
      const country = Country(
        id: 'US',
        name: 'United States',
        searchKeywords: ['usa', 'america'],
      );

      expect(country.id, 'US');
      expect(country.name, 'United States');
      expect(country.searchKeywords, ['usa', 'america']);
    });

    test('fromMap creates Country object with complete data', () {
      final map = {
        'id': 'GB',
        'name': 'United Kingdom',
        'searchKeywords': ['uk', 'britain'],
      };

      final country = Country.fromMap(map);

      expect(country.id, 'GB');
      expect(country.name, 'United Kingdom');
      expect(country.searchKeywords, ['uk', 'britain']);
    });

    test('fromMap handles missing/null data with defaults', () {
      final country = Country.fromMap({});

      expect(country.id, '');
      expect(country.name, '');
      expect(country.searchKeywords, isEmpty);
    });

    test('toMap converts Country to map correctly', () {
      const country = Country(
        id: 'CA',
        name: 'Canada',
        searchKeywords: ['canada', 'ca'],
      );

      final map = country.toMap();

      expect(map['id'], 'CA');
      expect(map['name'], 'Canada');
      expect(map['searchKeywords'], ['canada', 'ca']);
    });

    test('copyWith creates a new instance with updated values', () {
      const country = Country(
        id: 'MX',
        name: 'Mexico',
        searchKeywords: ['mexico'],
      );

      final updated = country.copyWith(name: 'Estados Unidos Mexicanos');

      expect(updated.id, 'MX');
      expect(updated.name, 'Estados Unidos Mexicanos');
      expect(updated.searchKeywords, ['mexico']);
      expect(identical(country, updated), isFalse);
    });

    test('Equality and hashCode work correctly', () {
      const country1 = Country(
        id: 'JP',
        name: 'Japan',
        searchKeywords: ['japan', 'jp'],
      );
      const country2 = Country(
        id: 'JP',
        name: 'Japan',
        searchKeywords: ['japan', 'jp'],
      );
      const country3 = Country(
        id: 'CN',
        name: 'China',
        searchKeywords: ['china'],
      );

      // Reflexive
      expect(country1, equals(country1));
      
      // Symmetric
      expect(country1, equals(country2));
      expect(country2, equals(country1));
      
      // HashCode
      expect(country1.hashCode, equals(country2.hashCode));
      
      // Not equal
      expect(country1, isNot(equals(country3)));
      expect(country1, isNot(equals(null)));
      expect(country1, isNot(equals('not a country')));
    });

    test('toString returns the country name', () {
      const country = Country(id: 'FR', name: 'France', searchKeywords: []);
      expect(country.toString(), 'France');
    });

    test('copyWith returns same values when no arguments provided', () {
      const country = Country(id: 'DE', name: 'Germany', searchKeywords: ['germany']);
      final updated = country.copyWith();
      expect(updated, equals(country));
    });

    test('fromMap handles null values by using defaults', () {
      final map = {
        'id': null,
        'name': null,
        'searchKeywords': null,
      };
      final country = Country.fromMap(map);
      expect(country.id, '');
      expect(country.name, '');
      expect(country.searchKeywords, isEmpty);
    });
  });
}
