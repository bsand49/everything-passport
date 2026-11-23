import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:everything_passport/utils/image_utils.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../test_helper.dart';
import 'image_utils_test.mocks.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
void main() {
  group('ImageUtils', () {
    late MockClient mockClient;

    setUpAll(() {
      PathProviderPlatform.instance = FakePathProviderPlatform();
    });

    setUp(() {
      mockClient = MockClient();
    });

    test('downloadAndSaveImage returns file on success (200)', () async {
      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response.bytes([1, 2, 3], 200));

      final file = await ImageUtils.downloadAndSaveImage(
        'https://example.com/image.jpg',
        mockClient,
        fileName: 'test_image.jpg',
      );

      expect(file, isNotNull);
      expect(file!.path, endsWith('test_image.jpg'));
      expect(await file.readAsBytes(), [1, 2, 3]);
    });

    test('downloadAndSaveImage returns null on HTTP error', () async {
      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final file = await ImageUtils.downloadAndSaveImage(
        'https://example.com/image.jpg',
        mockClient,
      );

      expect(file, isNull);
    });

    test('downloadAndSaveImage returns null on exception', () async {
      when(mockClient.get(any)).thenThrow(Exception('Network error'));

      final file = await ImageUtils.downloadAndSaveImage(
        'https://example.com/image.jpg',
        mockClient,
      );

      expect(file, isNull);
    });
  });
}
