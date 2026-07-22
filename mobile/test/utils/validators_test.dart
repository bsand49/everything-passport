import 'package:flutter_test/flutter_test.dart';
import 'package:everything_passport/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('returns null for valid email', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
        expect(Validators.validateEmail('user.name+tag@domain.co.uk'), isNull);
      });

      test('returns error for empty or null email', () {
        expect(Validators.validateEmail(null), 'Please enter your email');
        expect(Validators.validateEmail(''), 'Please enter your email');
      });

      test('returns custom error message for empty or null email', () {
        expect(Validators.validateEmail('', message: 'Custom error'),
            'Custom error');
      });

      test('returns error for invalid email format', () {
        expect(
            Validators.validateEmail('invalid'), 'Please enter a valid email');
        expect(Validators.validateEmail('@domain.com'),
            'Please enter a valid email');
        expect(Validators.validateEmail('user@'), 'Please enter a valid email');
      });
    });

    group('validatePassword', () {
      test('returns null for valid password', () {
        expect(Validators.validatePassword('password123'), isNull);
        expect(Validators.validatePassword('123456'), isNull);
      });

      test('returns error for empty or null password', () {
        expect(Validators.validatePassword(null), 'Please enter a password');
        expect(Validators.validatePassword(''), 'Please enter a password');
      });

      test('returns custom error message for empty or null password', () {
        expect(Validators.validatePassword('', message: 'Custom error'),
            'Custom error');
      });

      test('returns error for short password', () {
        expect(Validators.validatePassword('12345'),
            'Password must be at least 6 characters');
      });
    });

    group('validateConfirmPassword', () {
      test('returns null when passwords match', () {
        expect(Validators.validateConfirmPassword('pass', 'pass'), isNull);
      });

      test('returns error when passwords do not match', () {
        expect(Validators.validateConfirmPassword('other', 'pass'),
            'Passwords do not match');
      });

      test('returns error when empty', () {
        expect(Validators.validateConfirmPassword('', 'pass'),
            'Please confirm your password');
        expect(Validators.validateConfirmPassword(null, 'pass'),
            'Please confirm your password');
      });
    });

    group('validateUsername', () {
      test('returns null for valid username', () {
        expect(Validators.validateUsername('john_doe'), isNull);
        expect(Validators.validateUsername('abc'), isNull);
      });

      test('returns error for empty or null username', () {
        expect(Validators.validateUsername(null), 'Username is required');
        expect(Validators.validateUsername(' '), 'Username is required');
      });

      test('returns error for short username', () {
        expect(Validators.validateUsername('ab'), 'Username too short');
      });

      test('returns error when username is not available', () {
        expect(Validators.validateUsername('taken', isAvailable: false),
            'Username already taken');
      });
    });

    group('validateRequired', () {
      test('returns null when value is not empty', () {
        expect(Validators.validateRequired('content'), isNull);
      });

      test('returns default error message when empty', () {
        expect(Validators.validateRequired(''), 'Field is required');
        expect(Validators.validateRequired(null), 'Field is required');
      });

      test('returns error message with field name', () {
        expect(Validators.validateRequired('', fieldName: 'Email'),
            'Email is required');
      });

      test('returns custom error message', () {
        expect(Validators.validateRequired('', message: 'Custom'), 'Custom');
      });
    });
  });
}
