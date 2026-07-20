import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/services/metadata_service.dart';
import 'package:everything_passport/models/country.dart';

import 'metadata_service_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<FirebaseFirestore>(as: #MockFirestore),
])
void main() {
  group('MetadataService', () {
    late FakeFirebaseFirestore mockFirestore;
    late MetadataService metadataService;

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
      metadataService = MetadataService(db: mockFirestore);
    });

    group('initialization', () {
      test('Constructor fallback defaults to FirebaseFirestore.instance', () {
        // Since Firebase is not initialized in unit tests, creating MetadataService without a db
        // will throw an exception when accessing FirebaseFirestore.instance. We assert that it throws
        // to ensure the default fallback code path is executed and covered.
        expect(() => MetadataService(), throwsA(anything));
      });
    });

    group('getCountries()', () {
      group('successful retrieval and mapping', () {
        test('returns correctly mapped and deserialized countries', () async {
          await mockFirestore.collection('metadata').doc('countries').set({
            'options': [
              {
                'id': 'US',
                'name': 'United States',
                'searchKeywords': ['usa', 'america']
              },
              {
                'id': 'GB',
                'name': 'United Kingdom',
                'searchKeywords': ['uk']
              },
            ]
          });

          final countries = await metadataService.getCountries();
          expect(countries, hasLength(2));

          // GB (United Kingdom) comes before US (United States) alphabetically
          expect(countries[0].id, 'GB');
          expect(countries[0].name, 'United Kingdom');
          expect(countries[0].searchKeywords, ['uk']);

          expect(countries[1].id, 'US');
          expect(countries[1].name, 'United States');
          expect(countries[1].searchKeywords, ['usa', 'america']);
        });

        test('returns sorted list of countries alphabetically by name',
            () async {
          await mockFirestore.collection('metadata').doc('countries').set({
            'options': [
              {
                'id': 'GB',
                'name': 'United Kingdom',
                'searchKeywords': ['uk']
              },
              {
                'id': 'US',
                'name': 'United States',
                'searchKeywords': ['usa']
              },
              {
                'id': 'CA',
                'name': 'Canada',
                'searchKeywords': ['ca']
              },
            ]
          });

          final countries = await metadataService.getCountries();
          expect(countries, hasLength(3));
          expect(countries[0].name, 'Canada');
          expect(countries[1].name, 'United Kingdom');
          expect(countries[2].name, 'United States');
        });
      });

      group('caching behavior', () {
        test('uses cache on subsequent calls', () async {
          await mockFirestore.collection('metadata').doc('countries').set({
            'options': [
              {
                'id': 'US',
                'name': 'United States',
                'searchKeywords': ['usa']
              },
            ]
          });

          final countries1 = await metadataService.getCountries();

          // Update Firestore directly
          await mockFirestore.collection('metadata').doc('countries').set({
            'options': [
              {
                'id': 'GB',
                'name': 'United Kingdom',
                'searchKeywords': ['uk']
              },
            ]
          });

          final countries2 = await metadataService.getCountries();

          expect(countries2[0].id, 'US');
          expect(countries1, same(countries2));
        });

        test('bypasses cache when forceRefresh is true', () async {
          await mockFirestore.collection('metadata').doc('countries').set({
            'options': [
              {
                'id': 'US',
                'name': 'United States',
                'searchKeywords': ['usa']
              },
            ]
          });

          await metadataService.getCountries();

          await mockFirestore.collection('metadata').doc('countries').set({
            'options': [
              {
                'id': 'GB',
                'name': 'United Kingdom',
                'searchKeywords': ['uk']
              },
            ]
          });

          final countries2 =
              await metadataService.getCountries(forceRefresh: true);

          expect(countries2[0].id, 'GB');
        });
      });

      group('error handling and edge cases', () {
        test('returns empty list if doc does not exist', () async {
          final countries = await metadataService.getCountries();
          expect(countries, isEmpty);
        });

        test('handles missing options field', () async {
          await mockFirestore
              .collection('metadata')
              .doc('countries')
              .set({'something_else': 'data'});
          final countries = await metadataService.getCountries();
          expect(countries, isEmpty);
        });

        test('handles malformed options list structure gracefully', () async {
          await mockFirestore.collection('metadata').doc('countries').set({
            'options': [
              'not_a_map_value'
            ] // throws a TypeError inside _fromFirestore during casting
          });

          final countries = await metadataService.getCountries();
          expect(countries, isEmpty);
        });

        test('returns empty list on Firestore error with no cache', () async {
          final mockFailingFirestore = MockFirestore();
          when(mockFailingFirestore.collection(any))
              .thenThrow(Exception('Firestore Error'));

          final failingMetadataService =
              MetadataService(db: mockFailingFirestore);
          final countries = await failingMetadataService.getCountries();
          expect(countries, isEmpty);
        });

        test('returns cached data on Firestore error during refresh', () async {
          await mockFirestore.collection('metadata').doc('countries').set({
            'options': [
              {'id': 'US', 'name': 'USA', 'searchKeywords': []}
            ]
          });

          await metadataService.getCountries();

          final mockToggleFirestore = MockFirestore();
          var fail = false;
          when(mockToggleFirestore.collection(any)).thenAnswer((invocation) {
            if (fail) throw Exception('Firestore Error');
            final path = invocation.positionalArguments[0] as String;
            return mockFirestore.collection(path);
          });

          final serviceToggle = MetadataService(db: mockToggleFirestore);
          await serviceToggle.getCountries();

          fail = true;
          final result = await serviceToggle.getCountries(forceRefresh: true);
          expect(result, hasLength(1));
          expect(result[0].id, 'US');
        });
      });
    });

    group('clearCache()', () {
      test('clears memory cache', () async {
        await mockFirestore.collection('metadata').doc('countries').set({
          'options': [
            {'id': 'US', 'name': 'USA', 'searchKeywords': []}
          ]
        });

        final countries1 = await metadataService.getCountries();
        expect(countries1, hasLength(1));

        metadataService.clearCache();

        await mockFirestore
            .collection('metadata')
            .doc('countries')
            .set({'options': []});

        final countries2 = await metadataService.getCountries();
        expect(countries2, isEmpty);
      });
    });

    group('toFirestore()', () {
      test('serializes list of countries correctly', () {
        final countries = <Country>[
          const Country(
              id: 'US', name: 'United States', searchKeywords: ['usa'])
        ];

        final data =
            MetadataService.toFirestore(countries, SetOptions(merge: true));

        final options = data['options'] as List<dynamic>;
        expect(options, hasLength(1));

        final firstCountry = options[0] as Map<String, dynamic>;
        expect(firstCountry['id'], 'US');
        expect(firstCountry['name'], 'United States');
        expect(firstCountry['searchKeywords'], ['usa']);
      });
    });
  });
}
