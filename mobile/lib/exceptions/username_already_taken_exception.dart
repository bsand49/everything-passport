/// Exception thrown when a user attempts to claim a username that is already taken.
class UsernameAlreadyTakenException(final String username)
    implements Exception {
  @override
  String toString() => 'Username "$username" is already taken.';
}
