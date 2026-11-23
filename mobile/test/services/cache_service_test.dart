import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/services/cache_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../test_helper.dart';

void main() {
  group('CacheService', () {
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('cache_service_test');
      PathProviderPlatform.instance = FakePathProviderPlatform(
        tempPath: tempDir.path,
      );
    });

    tearDownAll(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('clearAll clears the metadata service cache', () async {
      final metadataService = FakeMetadataService();
      final cacheService = CacheService(service: metadataService);

      await cacheService.clearAll();

      expect(metadataService.clearCacheCalls, 1);
    });
  });
}
