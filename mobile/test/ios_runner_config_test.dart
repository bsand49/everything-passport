import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS runner configuration', () {
    // Google Sign-In crashes on iOS when CFBundleURLTypes lacks the OAuth
    // reversed client ID scheme, and no automated test exercises the native
    // sign-in flow — so guard the plist entry directly.
    test('Info.plist registers a Google Sign-In callback URL scheme', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(plist, contains('<key>CFBundleURLTypes</key>'));
      expect(plist, contains('<key>CFBundleURLSchemes</key>'));
      expect(plist, contains('com.googleusercontent.apps.'));
    });
  });
}
