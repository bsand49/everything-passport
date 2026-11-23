import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/services/cache_service.dart';

import '../test_helper.dart';

void main() {
  group('CacheService', () {
    test('clearAll clears the metadata service cache', () async {
      final metadataService = FakeMetadataService();
      final cacheService = CacheService(
        service: metadataService,
        clearImageCache: () async {},
      );

      await cacheService.clearAll();

      expect(metadataService.clearCacheCalls, 1);
    });

    test('clearAll propagates image cache errors', () async {
      final cacheService = CacheService(
        service: FakeMetadataService(),
        clearImageCache: () async => throw Exception('disk error'),
      );

      await expectLater(cacheService.clearAll(), throwsException);
    });
  });
}
