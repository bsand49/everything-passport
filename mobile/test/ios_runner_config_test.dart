import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS runner configuration', () {
    // Google Sign-In crashes on iOS when CFBundleURLTypes lacks the OAuth
    // reversed client ID scheme, and no automated test exercises the native
    // sign-in flow — so guard the plist entry directly.
    test('Info.plist registers the Google Sign-In callback URL scheme', () {
      final infoPlist = File('ios/Runner/Info.plist');
      final googlePlist = File('ios/Runner/GoogleService-Info.plist');
      expect(infoPlist.existsSync(), isTrue);

      final contents = infoPlist.readAsStringSync();
      expect(contents, contains('<key>CFBundleURLTypes</key>'));
      expect(contents, contains('<key>CFBundleURLSchemes</key>'));

      // When a real GoogleService-Info.plist is present (local dev), the
      // registered scheme must match its REVERSED_CLIENT_ID exactly. CI
      // generates a dummy plist, so only the scheme format is checked there.
      String? reversedClientId;
      if (googlePlist.existsSync()) {
        final match = RegExp(
          r'<key>REVERSED_CLIENT_ID</key>\s*<string>([^<]+)</string>',
        ).firstMatch(googlePlist.readAsStringSync());
        final value = match?.group(1);
        if (value != null && !value.contains('dummy')) {
          reversedClientId = value;
        }
      }

      if (reversedClientId != null) {
        expect(
          contents,
          contains('<string>$reversedClientId</string>'),
          reason: 'Info.plist scheme must match REVERSED_CLIENT_ID',
        );
      } else {
        expect(contents, contains('com.googleusercontent.apps.'));
      }
    });
  });
}
