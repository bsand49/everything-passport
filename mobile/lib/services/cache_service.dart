import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'metadata_service.dart';

/// Clears app-managed caches: the in-memory Firestore metadata cache and
/// downloaded images (e.g. profile pictures served by `cached_network_image`).
///
/// Firestore's own offline persistence is managed by the SDK and is not
/// cleared here — `FirebaseFirestore.clearPersistence()` cannot run while
/// snapshot listeners are active, and the persisted cache is already scoped
/// per install and bounded by `Settings.cacheSizeBytes`.
class CacheService {
  CacheService({
    required MetadataService service,
    Future<void> Function()? clearImageCache,
  }) : _metadataService = service,
       _clearImageCache = clearImageCache ?? DefaultCacheManager().emptyCache;

  final MetadataService _metadataService;
  final Future<void> Function() _clearImageCache;

  /// Clears all app-managed caches.
  ///
  /// Throws if the image cache cannot be cleared so callers can report the
  /// failure instead of claiming success.
  Future<void> clearAll() async {
    await _metadataService.clearCache();
    await _clearImageCache();
  }
}
