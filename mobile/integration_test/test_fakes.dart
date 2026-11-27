import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Shared fakes for the mock-backed integration tests. google_sign_in_mocks is
// not used because its account fake does not implement the v7
// `authorizationClient` API that AuthService.signInWithGoogle relies on.

class FakeGoogleSignInAuthorizationClient extends Fake
    implements GoogleSignInAuthorizationClient {
  @override
  Future<GoogleSignInClientAuthorization?> authorizationForScopes(
    List<String> scopes,
  ) async {
    return const GoogleSignInClientAuthorization(
      accessToken: 'fake-access-token',
    );
  }

  @override
  Future<GoogleSignInClientAuthorization> authorizeScopes(
    List<String> scopes,
  ) async {
    return const GoogleSignInClientAuthorization(
      accessToken: 'fake-access-token',
    );
  }
}

class FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  @override
  String get id => 'fake-google-id';

  @override
  String get email => 'e2e@example.com';

  @override
  String? get displayName => 'E2E User';

  @override
  String? get photoUrl => null;

  @override
  GoogleSignInAuthentication get authentication =>
      const GoogleSignInAuthentication(idToken: 'fake-id-token');

  @override
  GoogleSignInAuthorizationClient get authorizationClient =>
      FakeGoogleSignInAuthorizationClient();
}

class FakeGoogleSignIn extends Fake implements GoogleSignIn {
  /// When set, [authenticate] throws this instead of returning an account.
  Object? authenticateError;
  int authenticateCalls = 0;
  int signOutCalls = 0;

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const <String>[],
  }) async {
    authenticateCalls++;
    final error = authenticateError;
    if (error != null) throw error;
    return FakeGoogleSignInAccount();
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
