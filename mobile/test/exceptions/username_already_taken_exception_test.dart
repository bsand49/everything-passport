import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/exceptions/username_already_taken_exception.dart';

void main() {
  group('UsernameAlreadyTakenException', () {
    const testUsername = 'taken_hero';

    group('Initialization', () {
      test('stores the username correctly', () {
        final exception = UsernameAlreadyTakenException(testUsername);
        expect(exception.username, equals(testUsername));
      });
    });

    group('toString()', () {
      test('returns a correctly formatted error message', () {
        final exception = UsernameAlreadyTakenException(testUsername);
        expect(
          exception.toString(),
          equals('Username "taken_hero" is already taken.'),
        );
      });
    });
  });
}
