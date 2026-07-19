import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/country.dart';

class MetadataService {
  final FirebaseFirestore _db;
  List<Country>? _cachedCountries;

  MetadataService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static List<Country> _fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? _) {
    final data = snapshot.data();
    final List<dynamic> options = data?['options'] ?? [];
    return options
        .map((item) => Country.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static Map<String, Object?> toFirestore(List<Country> countries, SetOptions? _) {
    return {
      'options': countries.map((c) => c.toMap()).toList(),
    };
  }

  /// Fetches the list of countries from the metadata collection.
  ///
  /// Results are cached in memory. Use [forceRefresh] to bypass the cache.
  Future<List<Country>> getCountries({bool forceRefresh = false}) async {
    if (_cachedCountries != null && !forceRefresh) {
      return _cachedCountries!;
    }

    try {
      final docRef = _db
          .collection('metadata')
          .doc('countries')
          .withConverter<List<Country>>(
            fromFirestore: _fromFirestore,
            toFirestore: toFirestore,
          );

      final doc = await docRef.get();
      final countries = doc.data() ?? [];

      // Sort countries by name alphabetically
      countries.sort((a, b) => a.name.compareTo(b.name));

      _cachedCountries = countries;
      return countries;
    } catch (e) {
      debugPrint('Error fetching countries: $e');
      // Return cached data if available, even if forceRefresh was true,
      // as a fallback during network errors.
      return _cachedCountries ?? [];
    }
  }

  /// Clears the in-memory cache.
  void clearCache() {
    _cachedCountries = null;
  }
}
