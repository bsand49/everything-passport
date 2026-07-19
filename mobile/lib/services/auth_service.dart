import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  // Google Sign-In Scopes
  static const List<String> _googleScopes = ['email', 'profile'];

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Current user getter for synchronous checks.
  User? get currentUser => _auth.currentUser;

  /// Stream of [User] auth state changes.
  Stream<User?> get user => _auth.authStateChanges();

  /// Sign in with Email and Password.
  Future<UserCredential?> signInWithEmail(String email, String password) async {
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
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Sign up error [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected sign up error: $e');
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
          await googleUser.authorizationClient.authorizationForScopes(_googleScopes) ??
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
  Future<void> sendPasswordResetEmail(String email) async {
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
      debugPrint('AuthService: Account deletion error [${e.code}]: ${e.message}');
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
