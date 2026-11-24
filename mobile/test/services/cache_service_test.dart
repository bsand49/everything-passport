import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/services/cache_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../test_helper.dart';

class _TempPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _TempPathProviderPlatform(this._path);

  final String _path;

  @override
  Future<String?> getTemporaryPath() async => _path;

  @override
  Future<String?> getApplicationSupportPath() async => _path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test(
      'clearAll clears the default image cache when none is injected',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'cache_service_test_',
        );
        addTearDown(() => tempDir.delete(recursive: true));
        PathProviderPlatform.instance = _TempPathProviderPlatform(tempDir.path);
        // flutter_cache_manager persists its index via sqflite; the ffi
        // factory gives tests a real database without platform channels.
        databaseFactory = databaseFactoryFfi;

        final metadataService = FakeMetadataService();
        final cacheService = CacheService(service: metadataService);

        await cacheService.clearAll();

        expect(metadataService.clearCacheCalls, 1);
      },
    );
  });
}
