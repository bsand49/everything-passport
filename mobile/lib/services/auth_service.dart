import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../exceptions/email_verification_send_exception.dart';

class AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn}) {
  final FirebaseAuth _auth = auth ?? FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  // Google Sign-In Scopes
  static const List<String> _googleScopes = ['email', 'profile'];

  /// Current user getter for synchronous checks.
  User? get currentUser => _auth.currentUser;

  /// Stream of [User] auth state changes.
  ///
  /// Uses [FirebaseAuth.userChanges] rather than
  /// [FirebaseAuth.authStateChanges] so that snapshots refreshed via
  /// [User.reload] (for example after email verification) are emitted too.
  Stream<User?> get user => _auth.userChanges();

  /// Whether [user] is an email/password account that has not verified its
  /// email address. Google sign-in accounts are verified automatically and
  /// never require this.
  bool requiresEmailVerificationFor(User? user) {
    if (user == null || user.emailVerified) return false;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  /// Sign in with Email and Password.
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Sign in error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected sign in error: $e');
      rethrow;
    }
  }

  /// Register with Email and Password.
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        // Capture the UID before the send so the timestamp is always
        // recorded against the account that received the email.
        final uid = user.uid;
        try {
          await user.sendEmailVerification();
          _recordVerificationEmailSent(uid);
        } catch (e) {
          debugPrint('AuthService: Email verification send failed: $e');
          // The account exists at this point, so surface the failure as a
          // distinct error instead of pretending the email was sent.
          throw EmailVerificationSendException(e);
        }
      }
      return credential;
    } on EmailVerificationSendException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Sign up error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected sign up error: $e');
      rethrow;
    }
  }

  /// Clock used for verification-email cooldown bookkeeping. Overridable in
  /// tests; production code leaves the default.
  DateTime Function() now = DateTime.now;

  /// Successful verification-email send times, keyed by the UID of the
  /// account that received the email, so the resend cooldown applies per
  /// account rather than per banner instance.
  final Map<String, DateTime> _verificationEmailSentAt = {};

  final ValueNotifier<int> _verificationEmailSentAtVersion = ValueNotifier(0);

  /// Notifies listeners whenever a verification-email send is recorded so
  /// mounted banners can refresh their cooldown display.
  ValueListenable<int>? get verificationEmailSentAtVersion =>
      _verificationEmailSentAtVersion;

  void _recordVerificationEmailSent(String uid) {
    _verificationEmailSentAt[uid] = now();
    _verificationEmailSentAtVersion.value++;
  }

  /// The time the last verification email was successfully sent to [uid],
  /// or `null` if none has been sent this session.
  DateTime? verificationEmailSentAtFor(String? uid) =>
      uid == null ? null : _verificationEmailSentAt[uid];

  /// Sends a verification email to the currently signed-in user.
  ///
  /// Throws a [StateError] when no user is signed in.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user to verify.');
    }
    try {
      await user.sendEmailVerification();
      _recordVerificationEmailSent(user.uid);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService: Email verification error [${e.code}]: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected email verification error: $e');
      rethrow;
    }
  }

  /// Reloads the current user so [User.emailVerified] reflects the latest
  /// server state. Does nothing when no user is signed in.
  Future<void> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: User reload error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected user reload error: $e');
      rethrow;
    }
  }

  /// Sign in with Google.
  ///
  /// Returns [UserCredential] if successful, or `null` if the user cancels.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final clientAuth =
          await googleUser.authorizationClient.authorizationForScopes(
            _googleScopes,
          ) ??
          await googleUser.authorizationClient.authorizeScopes(_googleScopes);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      debugPrint('AuthService: Google sign in error [${e.code}]');
      return null;
    } catch (e) {
      debugPrint('AuthService: Unexpected Google sign in error: $e');
      rethrow;
    }
  }

  /// Sends a password reset email to the specified [email].
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Password reset error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected password reset error: $e');
      rethrow;
    }
  }

  /// Deletes the currently authenticated user's account.
  ///
  /// **Warning**: This action is permanent.
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        await signOut();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService: Account deletion error [${e.code}]: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected account deletion error: $e');
      rethrow;
    }
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('AuthService: Sign out error: $e');
      rethrow;
    }
  }
}
