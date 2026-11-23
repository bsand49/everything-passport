import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/country.dart';

class MetadataService {
  MetadataService({
    FirebaseFirestore? db,
    this.cacheTtl = const Duration(hours: 24),
  }) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// How long the in-memory cache is considered fresh. The cache lives only
  /// for the app session — a cold start always re-fetches.
  final Duration cacheTtl;

  List<Country>? _cachedCountries;
  DateTime? _cachedAt;

  static List<Country> _fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data();
    final List<dynamic> options = data?['options'] ?? [];
    return options
        .map((item) => Country.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static Map<String, Object?> toFirestore(
    List<Country> countries,
    SetOptions? _,
  ) {
    return {'options': countries.map((c) => c.toMap()).toList()};
  }

  /// Fetches the list of countries from the metadata collection.
  ///
  /// Results are cached in memory for [cacheTtl]. Use [forceRefresh] to
  /// bypass the cache and re-fetch from Firestore. Stale cached data is
  /// still returned as a fallback when Firestore is unreachable.
  Future<List<Country>> getCountries({bool forceRefresh = false}) async {
    final isFresh =
        _cachedAt != null && DateTime.now().difference(_cachedAt!) < cacheTtl;
    if (!forceRefresh && _cachedCountries != null && isFresh) {
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

      _cachedCountries = List.unmodifiableOf(countries);
      _cachedAt = DateTime.now();
      return _cachedCountries!;
    } catch (e) {
      debugPrint('Error fetching countries: $e');
      // Return cached data if available, even if stale or forceRefresh was
      // true, as a fallback during network errors.
      return _cachedCountries ?? [];
    }
  }

  /// Clears the in-memory cache.
  Future<void> clearCache() async {
    _cachedCountries = null;
    _cachedAt = null;
  }
}
