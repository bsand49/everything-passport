/// Exception thrown when an account was created successfully but the initial
/// email verification message could not be sent.
class EmailVerificationSendException(final Object cause) implements Exception {
  @override
  String toString() => 'Verification email could not be sent: $cause';
}
