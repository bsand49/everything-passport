/// Exception thrown when a user attempts to claim a username that is already taken.
class UsernameAlreadyTakenException implements Exception {
  final String username;

  UsernameAlreadyTakenException(this.username);

  @override
  String toString() => 'Username "$username" is already taken.';
}
