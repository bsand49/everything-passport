import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/exceptions/email_verification_send_exception.dart';

void main() {
  group('EmailVerificationSendException', () {
    test('stores the cause', () {
      final cause = Exception('smtp unavailable');
      final exception = EmailVerificationSendException(cause);
      expect(exception.cause, same(cause));
    });

    test('returns a formatted error message', () {
      final exception = EmailVerificationSendException(
        Exception('smtp unavailable'),
      );
      expect(
        exception.toString(),
        equals(
          'Verification email could not be sent: '
          'Exception: smtp unavailable',
        ),
      );
    });
  });
}
