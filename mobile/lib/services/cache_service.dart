import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';

import 'metadata_service.dart';

/// Clears app-managed caches: the in-memory Firestore metadata cache and
/// downloaded images (e.g. profile pictures served by `cached_network_image`).
///
/// Firestore's own offline persistence is managed by the SDK and is not
/// cleared here — `FirebaseFirestore.clearPersistence()` cannot run while
/// snapshot listeners are active, and the persisted cache is already scoped
/// per install and bounded by `Settings.cacheSizeBytes`.
class CacheService {
  CacheService({required MetadataService service}) : _metadataService = service;

  final MetadataService _metadataService;

  /// Clears all app-managed caches.
  Future<void> clearAll() async {
    await _metadataService.clearCache();
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }
}
