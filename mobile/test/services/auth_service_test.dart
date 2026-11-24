import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/exceptions/email_verification_send_exception.dart';
import 'package:everything_passport/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<FirebaseAuth>(as: #MockAuth),
    MockSpec<User>(as: #MockUserMockito),
    MockSpec<GoogleSignIn>(as: #MockGoogleSignInMockito),
    MockSpec<GoogleSignInAccount>(as: #MockGoogleSignInAccountMockito),
    MockSpec<GoogleSignInAuthentication>(
      as: #MockGoogleSignInAuthenticationMockito,
    ),
    MockSpec<GoogleSignInAuthorizationClient>(
      as: #MockGoogleSignInAuthorizationClient,
    ),
    MockSpec<GoogleSignInClientAuthorization>(
      as: #MockGoogleSignInClientAuthorization,
    ),
    MockSpec<UserCredential>(as: #MockUserCredential),
  ],
)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      authService = AuthService(auth: mockAuth, googleSignIn: mockGoogleSignIn);
    });

    group('Initialization', () {
      test('throws FirebaseException when Firebase is not initialized', () {
        expect(() => AuthService(), throwsA(isA<FirebaseException>()));
      });

      test('initializes successfully with mockAuth', () {
        expect(() => AuthService(auth: mockAuth), returnsNormally);
      });

      test('throws FirebaseException when Firebase is not initialized (with googleSignIn)', () {
        expect(
          () => AuthService(googleSignIn: mockGoogleSignIn),
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('currentUser', () {
      test('returns null when not logged in', () {
        expect(authService.currentUser, isNull);
      });

      test('returns user when logged in', () async {
        await mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.email, 'test@example.com');
      });
    });

    group('user stream', () {
      test('emits correct user state', () async {
        final streamExpectation = expectLater(
          authService.user,
          emitsInOrder([isNull, isNotNull, isNull]),
        );

        await mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );
        await authService.signOut();

        await streamExpectation;
      });
    });

    group('signInWithEmail()', () {
      test('signs in with email and password successfully', () async {
        await mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        final result = await authService.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );
        expect(result?.user?.email, 'test@example.com');
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final failingAuth = MockAuth();
        when(
          failingAuth.signInWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service = AuthService(
          auth: failingAuth,
          googleSignIn: mockGoogleSignIn,
        );

        expect(
          () => service.signInWithEmail(
            email: 'error@test.com',
            password: 'pass',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final failingAuth = MockAuth();
        when(
          failingAuth.signInWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(Exception('Generic failure'));

        final service = AuthService(
          auth: failingAuth,
          googleSignIn: mockGoogleSignIn,
        );

        expect(
          () => service.signInWithEmail(
            email: 'error@test.com',
            password: 'pass',
          ),
          throwsException,
        );
      });
    });

    group('signUpWithEmail()', () {
      test('signs up with email and password successfully', () async {
        final result = await authService.signUpWithEmail(
          email: 'new@example.com',
          password: 'password123',
        );
        expect(result?.user?.email, 'new@example.com');
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final failingAuth = MockAuth();
        when(
          failingAuth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service = AuthService(
          auth: failingAuth,
          googleSignIn: mockGoogleSignIn,
        );

        expect(
          () => service.signUpWithEmail(
            email: 'error@test.com',
            password: 'pass',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final failingAuth = MockAuth();
        when(
          failingAuth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(Exception('Generic failure'));

        final service = AuthService(
          auth: failingAuth,
          googleSignIn: mockGoogleSignIn,
        );

        expect(
          () => service.signUpWithEmail(
            email: 'error@test.com',
            password: 'pass',
          ),
          throwsException,
        );
      });
    });

    group('requiresEmailVerificationFor()', () {
      MockUserMockito makeUser({
        required bool verified,
        String providerId = 'password',
      }) {
        final user = MockUserMockito();
        when(user.emailVerified).thenReturn(verified);
        when(user.providerData).thenReturn([_FakeUserInfo(providerId)]);
        return user;
      }

      test('returns false for null user', () {
        expect(authService.requiresEmailVerificationFor(null), isFalse);
      });

      test('returns false for verified password user', () {
        expect(
          authService.requiresEmailVerificationFor(makeUser(verified: true)),
          isFalse,
        );
      });

      test('returns false for unverified Google user', () {
        expect(
          authService.requiresEmailVerificationFor(
            makeUser(verified: false, providerId: 'google.com'),
          ),
          isFalse,
        );
      });

      test('returns true for unverified password user', () {
        expect(
          authService.requiresEmailVerificationFor(makeUser(verified: false)),
          isTrue,
        );
      });

      test('returns false for unverified user with no providers', () {
        final user = MockUserMockito();
        when(user.emailVerified).thenReturn(false);
        when(user.providerData).thenReturn([]);
        expect(authService.requiresEmailVerificationFor(user), isFalse);
      });
    });

    group('sendEmailVerification()', () {
      test('sends verification email for current user', () async {
        final user = MockUserMockito();
        when(user.uid).thenReturn('test_uid');
        when(user.sendEmailVerification()).thenAnswer((_) async {});
        final auth = MockAuth();
        when(auth.currentUser).thenReturn(user);

        final service = AuthService(auth: auth, googleSignIn: mockGoogleSignIn);

        await service.sendEmailVerification();
        verify(user.sendEmailVerification()).called(1);
        expect(service.verificationEmailSentAtFor('test_uid'), isNotNull);
      });

      test('increments the sent-at version notifier on send', () async {
        final user = MockUserMockito();
        when(user.uid).thenReturn('test_uid');
        when(user.sendEmailVerification()).thenAnswer((_) async {});
        final auth = MockAuth();
        when(auth.currentUser).thenReturn(user);

        final service = AuthService(auth: auth, googleSignIn: mockGoogleSignIn);

        expect(service.verificationEmailSentAtVersion?.value, 0);
        await service.sendEmailVerification();
        expect(service.verificationEmailSentAtVersion?.value, 1);
      });

      test('throws StateError when no user is signed in', () {
        final auth = MockAuth();
        when(auth.currentUser).thenReturn(null);

        final service = AuthService(auth: auth, googleSignIn: mockGoogleSignIn);

        expect(service.sendEmailVerification, throwsStateError);
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final user = MockUserMockito();
        when(user.sendEmailVerification())
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));
        final auth = MockAuth();
        when(auth.currentUser).thenReturn(user);

        final service = AuthService(auth: auth, googleSignIn: mockGoogleSignIn);

        expect(
          service.sendEmailVerification,
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final user = MockUserMockito();
        when(user.sendEmailVerification())
            .thenThrow(Exception('Generic failure'));
        final auth = MockAuth();
        when(auth.currentUser).thenReturn(user);

        final service = AuthService(auth: auth, googleSignIn: mockGoogleSignIn);

        expect(service.sendEmailVerification, throwsException);
      });
    });

    group('reloadCurrentUser()', () {
      test('reloads the current user', () async {
        final user = MockUserMockito();
        when(user.reload()).thenAnswer((_) async {});
        final auth = MockAuth();
        when(auth.currentUser).thenReturn(user);

        final service = AuthService(auth: auth, googleSignIn: mockGoogleSignIn);

        await service.reloadCurrentUser();
        verify(user.reload()).called(1);
      });

      test('does nothing when no user is signed in', () async {
        final auth = MockAuth();
        when(auth.currentUser).thenReturn(null);

        final service = AuthService(auth: auth, googleSignIn: mockGoogleSignIn);

        await expectLater(service.reloadCurrentUser(), completes);
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final user = MockUserMockito();
        when(user.reload())
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));
        final auth = MockAuth();
        when(auth.currentUser).thenReturn(user);

        final service = AuthService(auth: auth, googleSignIn: mockGoogleSignIn);

        expect(
          service.reloadCurrentUser,
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final user = MockUserMockito();
        when(user.reload()).thenThrow(Exception('Generic failure'));
        final auth = MockAuth();
        when(auth.currentUser).thenReturn(user);

        final service = AuthService(auth: auth, googleSignIn: mockGoogleSignIn);

        expect(service.reloadCurrentUser, throwsException);
      });
    });

    group('signUpWithEmail() email verification', () {
      AuthService serviceWithCredential({
        required MockUserMockito? user,
        Object? sendError,
      }) {
        final auth = MockAuth();
        final credential = MockUserCredential();
        when(credential.user).thenReturn(user);
        when(
          auth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => credential);
        if (user != null) {
          when(user.uid).thenReturn('new_user_uid');
          when(user.emailVerified).thenReturn(false);
          if (sendError != null) {
            when(user.sendEmailVerification()).thenThrow(sendError);
          } else {
            when(user.sendEmailVerification()).thenAnswer((_) async {});
          }
        }
        return AuthService(auth: auth, googleSignIn: mockGoogleSignIn);
      }

      test('sends verification email after sign up', () async {
        final user = MockUserMockito();
        final service = serviceWithCredential(user: user);

        await service.signUpWithEmail(
          email: 'new@example.com',
          password: 'password123',
        );

        verify(user.sendEmailVerification()).called(1);
      });

      test('does not send when credential has no user', () async {
        final service = serviceWithCredential(user: null);

        await service.signUpWithEmail(
          email: 'new@example.com',
          password: 'password123',
        );
      });

      test('throws EmailVerificationSendException when send fails', () async {
        final user = MockUserMockito();
        final service = serviceWithCredential(
          user: user,
          sendError: Exception('send failed'),
        );

        await expectLater(
          service.signUpWithEmail(
            email: 'new@example.com',
            password: 'password123',
          ),
          throwsA(isA<EmailVerificationSendException>()),
        );
        verify(user.sendEmailVerification()).called(1);
      });
    });

    group('signInWithGoogle()', () {
      test('returns user credentials on success', () async {
        final mockGoogle = MockGoogleSignInMockito();
        final mockAccount = MockGoogleSignInAccountMockito();
        final mockAuthDetails = MockGoogleSignInAuthenticationMockito();
        final mockAuthClient = MockGoogleSignInAuthorizationClient();
        final mockClientAuth = MockGoogleSignInClientAuthorization();

        when(mockGoogle.authenticate()).thenAnswer((_) async => mockAccount);
        when(mockAccount.authentication).thenReturn(mockAuthDetails);
        when(mockAccount.authorizationClient).thenReturn(mockAuthClient);
        when(mockAuthClient.authorizationForScopes(any))
            .thenAnswer((_) async => mockClientAuth);
        when(mockAuthDetails.idToken).thenReturn('fake-id');
        when(mockClientAuth.accessToken).thenReturn('fake-token');

        final service = AuthService(googleSignIn: mockGoogle, auth: mockAuth);

        final result = await service.signInWithGoogle();
        expect(result, isNotNull);
        expect(service.currentUser, isNotNull);
      });

      test(
        'passes id/access tokens and email/profile scopes to Firebase',
        () async {
          final mockGoogle = MockGoogleSignInMockito();
          final mockAccount = MockGoogleSignInAccountMockito();
          final mockAuthDetails = MockGoogleSignInAuthenticationMockito();
          final mockAuthClient = MockGoogleSignInAuthorizationClient();
          final mockClientAuth = MockGoogleSignInClientAuthorization();
          final mockFirebaseAuth = MockAuth();
          final mockCredential = MockUserCredential();

          when(mockGoogle.authenticate()).thenAnswer((_) async => mockAccount);
          when(mockAccount.authentication).thenReturn(mockAuthDetails);
          when(mockAccount.authorizationClient).thenReturn(mockAuthClient);
          when(mockAuthClient.authorizationForScopes(any))
              .thenAnswer((_) async => mockClientAuth);
          when(mockAuthDetails.idToken).thenReturn('fake-id');
          when(mockClientAuth.accessToken).thenReturn('fake-token');
          when(mockFirebaseAuth.signInWithCredential(any))
              .thenAnswer((_) async => mockCredential);

          final service = AuthService(
            googleSignIn: mockGoogle,
            auth: mockFirebaseAuth,
          );

          final result = await service.signInWithGoogle();
          expect(result, same(mockCredential));

          final credential =
              verify(mockFirebaseAuth.signInWithCredential(captureAny))
                      .captured
                      .single
                  as OAuthCredential;
          expect(credential.providerId, 'google.com');
          expect(credential.idToken, 'fake-id');
          expect(credential.accessToken, 'fake-token');

          final scopes =
              verify(mockAuthClient.authorizationForScopes(captureAny))
                      .captured
                      .single
                  as List<String>;
          expect(scopes, ['email', 'profile']);
        },
      );

      test(
        'calls authorizeScopes when authorizationForScopes returns null',
        () async {
          final mockGoogle = MockGoogleSignInMockito();
          final mockAccount = MockGoogleSignInAccountMockito();
          final mockAuthDetails = MockGoogleSignInAuthenticationMockito();
          final mockAuthClient = MockGoogleSignInAuthorizationClient();
          final mockClientAuth = MockGoogleSignInClientAuthorization();

          when(mockGoogle.authenticate()).thenAnswer((_) async => mockAccount);
          when(mockAccount.authentication).thenReturn(mockAuthDetails);
          when(mockAccount.authorizationClient).thenReturn(mockAuthClient);
          when(mockAuthClient.authorizationForScopes(any))
              .thenAnswer((_) async => null);
          when(mockAuthClient.authorizeScopes(any))
              .thenAnswer((_) async => mockClientAuth);
          when(mockAuthDetails.idToken).thenReturn('fake-id');
          when(mockClientAuth.accessToken).thenReturn('fake-token');

          final service = AuthService(googleSignIn: mockGoogle, auth: mockAuth);

          final result = await service.signInWithGoogle();
          expect(result, isNotNull);
          expect(service.currentUser, isNotNull);

          verify(mockAuthClient.authorizationForScopes(any)).called(1);
          verify(mockAuthClient.authorizeScopes(any)).called(1);
        },
      );

      test(
        'returns null on user cancellation (GoogleSignInException)',
        () async {
          final cancelledGoogle = MockGoogleSignInMockito();
          when(cancelledGoogle.authenticate()).thenThrow(
            const GoogleSignInException(
              code: GoogleSignInExceptionCode.canceled,
            ),
          );

          final service = AuthService(
            googleSignIn: cancelledGoogle,
            auth: mockAuth,
          );

          final result = await service.signInWithGoogle();
          expect(result, isNull);
        },
      );

      test('rethrows non-cancellation GoogleSignInException', () async {
        final failingGoogle = MockGoogleSignInMockito();
        when(failingGoogle.authenticate()).thenThrow(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
          ),
        );

        final service = AuthService(
          googleSignIn: failingGoogle,
          auth: mockAuth,
        );

        expect(
          () => service.signInWithGoogle(),
          throwsA(isA<GoogleSignInException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final failingGoogle = MockGoogleSignInMockito();
        when(failingGoogle.authenticate()).thenThrow(Exception('test'));

        final service = AuthService(
          googleSignIn: failingGoogle,
          auth: mockAuth,
        );

        expect(() => service.signInWithGoogle(), throwsException);
      });
    });

    group('sendPasswordResetEmail()', () {
      test('sends email successfully', () async {
        await authService.sendPasswordResetEmail(email: 'test@example.com');
        // Success if no exception thrown
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final failingAuth = MockAuth();
        when(
          failingAuth.sendPasswordResetEmail(
            email: anyNamed('email'),
            actionCodeSettings: anyNamed('actionCodeSettings'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service = AuthService(
          auth: failingAuth,
          googleSignIn: mockGoogleSignIn,
        );

        expect(
          () => service.sendPasswordResetEmail(email: 'error@test.com'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final failingAuth = MockAuth();
        when(
          failingAuth.sendPasswordResetEmail(
            email: anyNamed('email'),
            actionCodeSettings: anyNamed('actionCodeSettings'),
          ),
        ).thenThrow(Exception('Generic failure'));

        final service = AuthService(
          auth: failingAuth,
          googleSignIn: mockGoogleSignIn,
        );

        expect(
          () => service.sendPasswordResetEmail(email: 'error@test.com'),
          throwsException,
        );
      });
    });

    group('deleteAccount()', () {
      test('deletes account successfully', () async {
        await mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );
        expect(authService.currentUser, isNotNull);
        await authService.deleteAccount();
        expect(authService.currentUser, isNull);
      });

      test('does nothing if no user is logged in', () async {
        expect(authService.currentUser, isNull);
        await authService.deleteAccount();
        expect(authService.currentUser, isNull);
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final mockAuthFailing = MockAuth();
        final mockUser = MockUserMockito();

        when(mockAuthFailing.currentUser).thenReturn(mockUser);
        when(mockUser.delete())
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service = AuthService(
          auth: mockAuthFailing,
          googleSignIn: mockGoogleSignIn,
        );

        expect(
          () => service.deleteAccount(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final mockAuthFailing = MockAuth();
        final mockUser = MockUserMockito();

        when(mockAuthFailing.currentUser).thenReturn(mockUser);
        when(mockUser.delete()).thenThrow(Exception('Generic failure'));

        final service = AuthService(
          auth: mockAuthFailing,
          googleSignIn: mockGoogleSignIn,
        );

        expect(() => service.deleteAccount(), throwsException);
      });
    });

    group('signOut()', () {
      test('signs out successfully', () async {
        await mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );
        await authService.signOut();
        expect(mockAuth.currentUser, isNull);
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.signOut())
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service = AuthService(
          auth: failingAuth,
          googleSignIn: mockGoogleSignIn,
        );

        expect(() => service.signOut(), throwsA(isA<FirebaseAuthException>()));
      });

      test('rethrows generic Exception on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.signOut()).thenThrow(Exception('Generic failure'));

        final service = AuthService(
          auth: failingAuth,
          googleSignIn: mockGoogleSignIn,
        );

        expect(() => service.signOut(), throwsException);
      });
    });
  });
}

class _FakeUserInfo extends Fake implements UserInfo {
  _FakeUserInfo(this.providerId);

  @override
  final String providerId;
}
