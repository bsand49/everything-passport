import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:everything_passport/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<FirebaseAuth>(as: #MockAuth),
  MockSpec<User>(as: #MockUserMockito),
  MockSpec<GoogleSignIn>(as: #MockGoogleSignInMockito),
  MockSpec<GoogleSignInAccount>(as: #MockGoogleSignInAccountMockito),
  MockSpec<GoogleSignInAuthentication>(
      as: #MockGoogleSignInAuthenticationMockito),
  MockSpec<GoogleSignInAuthorizationClient>(
      as: #MockGoogleSignInAuthorizationClient),
  MockSpec<GoogleSignInClientAuthorization>(
      as: #MockGoogleSignInClientAuthorization),
  MockSpec<UserCredential>(as: #MockUserCredential),
])
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

      test(
          'throws FirebaseException when Firebase is not initialized (with googleSignIn)',
          () {
        expect(() => AuthService(googleSignIn: mockGoogleSignIn),
            throwsA(isA<FirebaseException>()));
      });
    });

    group('currentUser', () {
      test('returns null when not logged in', () {
        expect(authService.currentUser, isNull);
      });

      test('returns user when logged in', () async {
        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.email, 'test@example.com');
      });
    });

    group('user stream', () {
      test('emits correct user state', () async {
        final streamExpectation = expectLater(
          authService.user,
          emitsInOrder([
            isNull,
            isNotNull,
            isNull,
          ]),
        );

        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');
        await authService.signOut();

        await streamExpectation;
      });
    });

    group('signInWithEmail()', () {
      test('signs in with email and password successfully', () async {
        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');

        final result = await authService.signInWithEmail(
            email: 'test@example.com', password: 'password123');
        expect(result?.user?.email, 'test@example.com');
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.signInWithEmailAndPassword(
                email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signInWithEmail(
              email: 'error@test.com', password: 'pass'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.signInWithEmailAndPassword(
                email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(Exception('Generic failure'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signInWithEmail(
              email: 'error@test.com', password: 'pass'),
          throwsException,
        );
      });
    });

    group('signUpWithEmail()', () {
      test('signs up with email and password successfully', () async {
        final result = await authService.signUpWithEmail(
            email: 'new@example.com', password: 'password123');
        expect(result?.user?.email, 'new@example.com');
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.createUserWithEmailAndPassword(
                email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signUpWithEmail(
              email: 'error@test.com', password: 'pass'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.createUserWithEmailAndPassword(
                email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(Exception('Generic failure'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signUpWithEmail(
              email: 'error@test.com', password: 'pass'),
          throwsException,
        );
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

      test('calls authorizeScopes when authorizationForScopes returns null',
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
      });

      test('returns null on user cancellation (GoogleSignInException)',
          () async {
        final cancelledGoogle = MockGoogleSignInMockito();
        when(cancelledGoogle.authenticate()).thenThrow(
            const GoogleSignInException(
                code: GoogleSignInExceptionCode.canceled));

        final service =
            AuthService(googleSignIn: cancelledGoogle, auth: mockAuth);

        final result = await service.signInWithGoogle();
        expect(result, isNull);
      });

      test('rethrows generic Exception on failure', () async {
        final failingGoogle = MockGoogleSignInMockito();
        when(failingGoogle.authenticate()).thenThrow(Exception('test'));

        final service =
            AuthService(googleSignIn: failingGoogle, auth: mockAuth);

        expect(
          () => service.signInWithGoogle(),
          throwsException,
        );
      });
    });

    group('sendPasswordResetEmail()', () {
      test('sends email successfully', () async {
        await authService.sendPasswordResetEmail(email: 'test@example.com');
        // Success if no exception thrown
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.sendPasswordResetEmail(
                email: anyNamed('email'),
                actionCodeSettings: anyNamed('actionCodeSettings')))
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.sendPasswordResetEmail(email: 'error@test.com'),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.sendPasswordResetEmail(
                email: anyNamed('email'),
                actionCodeSettings: anyNamed('actionCodeSettings')))
            .thenThrow(Exception('Generic failure'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.sendPasswordResetEmail(email: 'error@test.com'),
          throwsException,
        );
      });
    });

    group('deleteAccount()', () {
      test('deletes account successfully', () async {
        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');
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

        final service =
            AuthService(auth: mockAuthFailing, googleSignIn: mockGoogleSignIn);

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

        final service =
            AuthService(auth: mockAuthFailing, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.deleteAccount(),
          throwsException,
        );
      });
    });

    group('signOut()', () {
      test('signs out successfully', () async {
        await mockAuth.createUserWithEmailAndPassword(
            email: 'test@example.com', password: 'password123');
        await authService.signOut();
        expect(mockAuth.currentUser, isNull);
      });

      test('rethrows FirebaseAuthException on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.signOut())
            .thenThrow(FirebaseAuthException(code: 'test', message: 'test'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signOut(),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('rethrows generic Exception on failure', () async {
        final failingAuth = MockAuth();
        when(failingAuth.signOut()).thenThrow(Exception('Generic failure'));

        final service =
            AuthService(auth: failingAuth, googleSignIn: mockGoogleSignIn);

        expect(
          () => service.signOut(),
          throwsException,
        );
      });
    });
  });
}
